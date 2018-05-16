package JavaScript::V8::CommonJS;

# use strictures 2;
use strict;
use warnings;
use JavaScript::V8;
use JavaScript::V8::CommonJS::Exception;
use File::ShareDir 'dist_dir';
use File::Basename 'dirname';
use File::Spec::Functions qw' rel2abs catdir catfile ';
use Cwd qw' getcwd realpath ';
use Data::Dumper;
# use Data::Printer;
use Carp qw' croak confess ';

our $VERSION = "0.04";

my $scripts_dir = realpath catdir(dirname(rel2abs(__FILE__)), '../../../share');
$scripts_dir = catdir(dist_dir('JavaScript-V8-CommonJS'))
    unless -d $scripts_dir;

sub new {
    my $class = shift;
    my $args = @_ == 0 ? {}
        : @_ > 1 ? {@_} : $_[0];

    croak "invalid arguments" unless ref $args eq 'HASH';

    bless my $self = {
        paths   => $args->{paths}   || [getcwd()],
        modules => $args->{modules} || {},
    }, $class;

    $self->{c} = $self->_build_ctx;
    $self;
}

sub c { shift->{c} }
sub modules { shift->{modules} }
sub paths { shift->{paths} }


sub _build_ctx {
    my $self = shift;
    my $c = JavaScript::V8::Context->new;

    # global functions
    for my $name (qw/ resolveModule requireNative evalModuleFile /) {

        $c->bind($name => sub {
            $self->can("_$name")->($self, @_);
        });
    }

    $c->bind(
        console => {
            log => \&_log,
            warn => \&_log,
            error => \&_log,
            info => \&_log,
        }
    );

    # require.js
    my $require_js = catfile($scripts_dir, "require.js");
    _eval($c, _slurp($require_js), $require_js);

    $c;
}

sub add_module {
    my ($self, $name, $module) = @_;
    my $mods = $self->modules;
    croak "add_module() error: '$name' already exists'" if exists $mods->{$name};
    $mods->{$name} = $module;
}


sub _requireNative {
    my ($self, $id) = @_;
    $self->modules->{$id};
}

sub _resolveModule {
    my ($self, $id, $current_module_file) = @_;

    confess "Can't traverse up the module paths." if $id =~ /\.\./;

    # relative
    if ($id =~ /^\.\//) {

        confess "Can't load relative module '$id' without current_module_file" unless $current_module_file;
        my $dir = dirname($current_module_file);
        my $file = catfile($dir, $id.'.js');
        return -e $file ? $file : undef;
    }


    # convert absolute path into module id
    $id =~ s/^\/+//g;

    # module id
    foreach my $path (@{$self->paths}) {
        my $file = catfile($path, $id.".js");
        return "$file" if -f $file;
    }

    return undef;
}


sub _readFile {
    my ($self, $path) = @_;
    return undef unless -f $path;
    _slurp($path);
}


sub _log {
    my (@lines) = @_;
    @lines = map { defined $_ ? $_ : 'undef' } map { ref $_ ? Dumper($_) : $_ } @lines;
    printf STDERR "# [console.log] @lines\n";
}

sub eval_file {
    my ($self, $file) = @_;
    croak "do not exist: $file" unless -f $file;
    $self->eval(_slurp($file), $file);
}

sub _evalModuleFile {
    my ($self, $file) = @_;
    croak "module '$file' do not exist" unless -f $file;
    my $module_code = _slurp($file);

    my $wrapper = qq!

        require.__modules["$file"] = {
            exports: {},
            __filename: "$file"
        };

        try {
            require.__callStack.push(require.__modules["$file"]);
            (function (require, module, exports, __filename, __dirname) { "use strict"; \%s })(require, require.__modules["$file"], require.__modules["$file"].exports, "$file");
            require.__modules["$file"].__is_compiled = true;
        }
        finally{
            require.__callStack.pop();
            if (require.__modules["$file"].__is_compiled) {
                delete require.__modules["$file"].__is_compiled;
            } else {
                delete require.__modules["$file"];
            }
        }

        1;
    !;

    # make oneline
    $wrapper =~ s/\n//g;

    # eval
    my $rv = $self->c->eval(sprintf($wrapper, $module_code), $file);

    if (!defined $rv && $@) {
        $@ =~ s/^Error: //;
        die $@
    }

    $rv;
}

sub eval {
    my $self = shift;
    _eval($self->c, @_);
};

sub _eval {
    my ($c, $code, $source) = @_;
    local $@ = undef;
    my $rv = $c->eval("try {$code} catch(e) {throw e.stack}", $source || ());
    if (!defined $rv && $@) {
        # warn "# eval error((($@)))";
        my $exception =  JavaScript::V8::CommonJS::Exception->new_from_string($@);
        my $ourStackCall = $exception->stack->[-1];
        $ourStackCall->{column} = $ourStackCall->{column} - 5 if ref $ourStackCall eq 'HASH'; # subtract "try {" length
        die $exception;
    }
    $rv;
};



sub _slurp {
  my $path = shift;

  CORE::open my $file, '<:encoding(UTF-8)', $path or croak qq{Can't open file "$path": $!};
  my $ret = my $content = '';
  while ($ret = $file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
  croak qq{Can't read from file "$path": $!} unless defined $ret;

  return $content;
}

1;
__END__

=encoding utf-8

=head1 NAME

JavaScript::V8::CommonJS - Modules/1.0 for JavaScript::V8

=head1 SYNOPSIS

    use JavaScript::V8::CommonJS;

    my $js = JavaScript::V8::CommonJS->new(paths => ["./modules"]);

    print $js->eval('require("foo").add(4, 2)');  # prints 6

    # modules/foo.js
    # exports.add = function(a, b) { return a + b }

=head1 DESCRIPTION

CommonJS implementation for JavaScript::V8. Currently only Module/1.0 spec is implemented. (Passing all unit tests at L<https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0>)

=head1 CONSTRUCTOR

=head2 new

All arguments are optional.

=over

=item paths

Arrayref of paths to search for modules. Default: [getcwd()].

=item modules

Hashref of native modules. Default: {}.

=back

=head1 METHODS

=head2 add_module(name => module)

Register native modules. Attempting to register a module twice is a fatal error.

    $js->add_module( http => {
        get => sub { ... },
        post => sub { ... },
        ...
    });

=head2 eval(js_code, source)

Evaluates javascript source code on the global context. JS exceptions are rethrown as L<JavaScript::V8::CommonJS::Exception> instances.

    $js->eval('require("program").doSomething()', "main")

The second argument is a source or filename to be reported on error messages.


=head2 eval_file(path)

    $js->eval_file("main.js")

=head2 c

Returns the JavaScript::V8::Context instance.

    # run v8 garbage collector
    $js->c->idle_notification

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
