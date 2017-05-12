package Dist::Zilla::Plugin::Rinci::Wrap;

our $DATE = '2016-06-02'; # DATE
our $VERSION = '0.13'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp::Meta ();
use Perinci::Sub::Wrapper qw(wrap_sub);

use Moose;
use experimental 'smartmatch';
use namespace::autoclean;

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

# the content will actually be eval'ed
has debug => (
    isa     => 'Bool',
    default => sub { 0 },
    is      => 'rw',
);

# the content will actually be eval'ed
has wrap_args => (
    isa     => 'Str',
    default => sub { '{}' },
    is      => 'rw',
);

has _wrap_args_compiled => (
    isa     => 'Bool',
    is      => 'rw',
);

has _prereqs => (
    is      => 'rw',
);
has _registered_modules => (
    is      => 'rw',
    default => sub { {} },
);

has exclude_func => (
    is => 'rw',
);
has include_func => (
    is => 'rw',
);

sub mvp_multivalue_args { qw(exclude_func include_func) }

sub _squish_code {
    my ($self, $code) = @_;
    return $code if $self->debug;
    for ($code) {
        s/^\s*#.+//mg; # comment line on its own
        s/##.*//mg;    # trailing comment using ##
        s/^\s+//mg;    # indentation
        s/\n+/ /g;     # newline
    }
    $code;
}

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    state $wrap_args;
    unless ($self->_wrap_args_compiled) {
        $self->log_debug("Compiling code in wrap_args option ...");
        my $val = $self->wrap_args;
        if ($val) {
            $val = eval $val;
            $self->log_fatal('wrap_args must evaluate to a hashref')
                unless ref($val) eq 'HASH';
            $wrap_args = $val;
        } else {
            $wrap_args = {};
        }
        $self->_wrap_args_compiled(1);
    }

    my $fname = $file->name;
    $self->log_debug("Processing file $fname ...");

    my $is_lib;
    my $req_name = $1;
    if ($fname =~ m!lib/(.+\.pm)$!) {
        $is_lib = 1;
        $req_name = $1;
    } elsif ($fname =~ m!(?:bin|script)/.+$!) {
        # we need to just compile the script but not execute it, like 'perl -c',
        # but we also need to read its %SPEC. hopefully most apps put their code
        # in lib/App/Foo.pm instead of in the script bin/foo itself.
        $self->log("$fname: WARN: Embedding wrapper code on script ".
                       "not yet supported, skipped");
        return;
    } else {
        #$self->log_debug("$fname: not a module or a script, skipped");
        return;
    }

    my $pkg_name = $req_name;
    $pkg_name =~ s/\.pm$//;
    $pkg_name =~ s!/!::!g;

    # i do it this way (unshift @INC, "lib" + require "Foo/Bar.pm" instead of
    # unshift @INC, "." + require "lib/Foo/Bar.pm") in my all other Dist::Zilla
    # and Pod::Weaver plugin, so they can work together (require "Foo/Bar.pm"
    # and require "lib/Foo/Bar.pm" would cause Perl to load the same file twice
    # and generate redefine warnings).

    local @INC = ("lib", @INC);

    eval { require $req_name };
    if ($@) {
        $self->log_fatal("$fname: has compile errors: $@");
        return;
    }

    my @content = split /^/, $file->content;
    my %wres; # wrap results
    my $metas = do { no strict 'refs'; \%{"$pkg_name\::SPEC"} };

    my @requires; # list of require lines that the wrapper code needs
    my %mods; # list of mentioned modules
    # generate wrapper for all subs
    for my $sub_name (keys %$metas) {
        next unless $sub_name =~ /\A\w+\z/; # skip non-functions
        $self->log_debug("Generating wrapper code for sub '$sub_name' ...");
        if ($self->exclude_func &&
                grep { $_ eq $sub_name } @{ $self->exclude_func }) {
            $self->log_debug("Skipped sub '$sub_name' (listed in exclude_func) ...");
            next;
        }
        if ($self->include_func &&
                !(grep { $_ eq $sub_name } @{ $self->include_func })) {
            $self->log_debug("Skipped sub '$sub_name' (not listed in include_func) ...");
            next;
        }
        my %wrap_args = (
            %{ $wrap_args },
            %{ $metas->{$_}{"x.dist.zilla.plugin.rinci.wrap.wrap_args"} // {} },
            sub_name  => "$pkg_name\::$sub_name",
            meta      => $metas->{$sub_name},
            meta_name => "\$$pkg_name\::SPEC{$sub_name}",
            _extra_sah_compiler_args => {comment=>0},
            embed=>1,
        );
        my $res = wrap_sub(%wrap_args);
        unless ($res->[0] == 200) {
            $self->log_fatal("Can't wrap $sub_name: $res->[0] - $res->[1]");
            return;
        }
        $wres{$sub_name} = $res->[2];
        my $src = $res->[2]{source};
        for (split /^/, $src->{presub1}) {
            push @requires, $_ unless $_ ~~ @requires;
            if (/^\s*(?:use|require|no) \s+ (\w+(?:::\w+)*)/x) {
                $mods{$1}++;
            }
        }
    } # for each key of metas

    return unless keys %wres;

    # register prereqs for validator code
    {
        require Module::CoreList;
        for my $mod (sort keys %mods) {
            next if Module::CoreList::is_core($mod, undef);
            next if $self->_registered_modules->{$mod};
            if ($self->zilla->prereqs->cpan_meta_prereqs->{requirements}{$mod}) {
                $self->log_debug("Prereq for validator code has already been specified in dist.ini: $mod");
                next;
            }
            $self->log("Adding prereq for validator code: $mod");
            $self->zilla->register_prereqs(
                {phase=>'runtime'}, $mod => 0);
            $self->_registered_modules->{$mod}++;
        }
    }

    my $i = 0; # line number
    my $in_pod;
    my $sub_name; # current subname
    my $sub_indent;

    my $has_preamble;
    my $has_postamble;
    my $has_put_preamble;
    my $has_put_postamble;

    my $sig = " ## this line is put by " . __PACKAGE__;

  LINE:
    for my $line (@content) {
        $i++;
        if ($line =~ /^=cut\b/x) {
            $in_pod = 0;
            next;
        }
        next if $in_pod;
        if ($line =~ /^=\w+/x) {
            $in_pod++;
            next;
        }

        if ($line =~ /^(\s*)sub \s+ (\w+)(?: \s* \{ \s* (\#\s*NO_RINCI_WRAP) )?/x) {
            my $no_wrap;
            $self->log_debug("Found sub declaration: $2");
            my $first_sub = !$sub_name;
            ($sub_indent, $sub_name, $no_wrap) = ($1, $2, $3);

            # XXX last sub doesn't get this check
            if ($has_postamble && !$has_put_postamble) {
                $self->log_fatal("[sub $sub_name] hasn't put postamble ".
                                     "wrapper code yet");
            }

            unless ($wres{$sub_name}) {
                $self->log_debug("Skipped wrapping sub $sub_name (no metadata)");
                $sub_name = undef;
                next;
            }
            if ($no_wrap) {
                $self->log_debug("Skipped wrapping sub $sub_name (#NO_RINCI_WRAP directive)");
                $sub_name = undef;
                next;
            }
            my $presub2 = "\$SPEC{$sub_name} = " . Data::Dmp::Meta::dmp({old_data=>"\$SPEC{$sub_name}"}, $wres{$sub_name}{meta}) . ";";
            if ($presub2 =~ /\S/) {
                $line = "\n$sub_indent# [Rinci::Wrap] END presub2\n$line" if $self->debug;
                $line = "$presub2 $line";
                $line = "\n$sub_indent# [Rinci::Wrap] BEGIN presub2\n$line" if $self->debug;
            }
            $has_preamble      = $wres{$sub_name}{source}{preamble} =~ /\S/;
            $has_postamble     = $wres{$sub_name}{source}{postamble} =~ /\S/;
            $has_put_preamble  = 0;
            $has_put_postamble = 0;

            if ($first_sub) {
                # this is the first sub, let's put all requires here
                $line = "\n$sub_indent# [Rinci::Wrap] END presub1\n$line" if $self->debug;
                chomp $line;
                $line = $self->_squish_code(join "", @requires) . " $line" . $sig . "\n";
                $line = "\n$sub_indent# [Rinci::Wrap] BEGIN presub1\n$line" if $self->debug;
            }

            next;
        }

        next unless $sub_name;

        # 'my %args = @_' statement
        if ($line =~ /^(\s*)(my \s+ [\%\@\$]args \s* = .+)/x) {
            {
                last unless $has_preamble && !$has_put_preamble;
                $self->log_debug("[sub $sub_name] Found a place to insert preamble (after '$2' statement)");

                my $indent = $1;

                # remove comment that might interfere with preamble adding
                $line =~ s/(.+?)#.*/$1/;

                # put preamble code
                $line = "$indent\n$indent# [Rinci::Wrap] BEGIN preamble\n$line" if $self->debug;
                my $preamble = $wres{$sub_name}{source}{preamble};
                $line =~ s/\n//;
                $line .= " " . $self->_squish_code($preamble) .
                    ($self->debug ? "\n$indent" : "") . '$_w_res = do {' .
                    $sig . "\n";
                $line = "$line\n$indent# [Rinci::Wrap] END preamble\n" if $self->debug;
                $has_put_preamble = 1;
                next LINE;
            }
        }

        # sub closing statement
        if ($line =~ /^${sub_indent}\}/) {
            $self->log_debug("Found sub closing: $sub_name");
            next unless $wres{$sub_name};

            {
                if ($has_preamble && !$has_put_preamble) {
                    $self->log_fatal("[sub $sub_name] hasn't put preamble ".
                                         "wrapper code yet");
                }
                last unless $has_postamble && !$has_put_postamble;

                # put postamble code
                my $postamble = "}; " . # for closing of the do { block
                    $wres{$sub_name}{source}{postamble};
                $line = "\n$sub_indent# [Rinci::Wrap] END postamble\n$line"
                    if $self->debug;
                chomp $line;
                $line = $self->_squish_code($postamble) . " $line" . $sig . "\n";
                $line = "\n$sub_indent# [Rinci::Wrap] BEGIN postamble\n$line"
                    if $self->debug;
                $has_put_postamble = 1;

            }
            # mark sub done by deleting entry from %wres
            delete $wres{$sub_name};

            next LINE;
        }
    }

    if (keys %wres) {
        $self->log_fatal("Some subs are not yet wrapped (probably because I couldn't find sub declaration or a place to insert the preamble/postamble): ".
                             join(", ", sort keys %wres));
    }

    $self->log("Adding wrapper code to $fname ...");
    $file->content(join "", @content);
    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert wrapper-generated code

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Rinci::Wrap - Insert wrapper-generated code

=head1 VERSION

This document describes version 0.13 of Dist::Zilla::Plugin::Rinci::Wrap (from Perl distribution Dist-Zilla-Plugin-Rinci-Wrap), released on 2016-06-02.

=head1 SYNOPSIS

In F<dist.ini>:

 [Rinci::Wrap]
 ; optional, will be eval'ed as Perl code and passed to wrap_sub()
 wrap_args = { validate_result => 0, convert => {retry=>2} }
 ; optional, will not squish code and add marker comment
 debug=1
 ; optional, exclude some functions
 ;exclude_func=func1
 ;exclude_func=func2
 ; optional, only include specified functions
 ;include_func=func3
 ;include_func=func4

In your module:

 $SPEC{foo} = {
     v => 1.1,
     args => {
         arg1 => { schema => ['int*', default=>3] },
         arg2 => { },
     },
 };
 sub foo {
     my %args = @_;

     ... your code
     return [200, "OK", "some result"];
 }

output will be something like:

 $SPEC{foo} = {
     v => 1.1,
     args => {
         arg1 => { schema => ['int*', default=>3] },
         arg2 => { },
     },
 };
 require Scalar::Util; require Data::Dumper; { my $meta = $SPEC{foo}; $meta->{args}{arg1}{schema} = ["int", {req=>1, default=>3}, {}]; } # WRAP_PRESUB
 sub foo {
     my %args = @_;

     ... generated preamble code

     ... your code
     return [200, "OK", "some result"];

     ... generated postamble code
 }

=head1 DESCRIPTION

This plugin inserts code generated by L<Perinci::Sub::Wrapper> to your source
code during building. This lets you add functionalities like argument
validation, result validation, automatic retries, conversion of argument passing
style, currying, and so on.

Code is inserted in three places (see the above example in Synopsis):

=over

=item *

The first part (which is the part to load required modules and to modify
function metadata, e.g. normalize Sah schemas, etc) will be inserted right
before the opening of the subroutine (C<sub NAME {>).

=item *

The second part (which is the part to validate arguments and do stuffs before
performing the function) will be inserted at the start of subroutine body after
the C<my %args = @_;> (or C<my $args = $_[0] // {};> if you accept arguments
from a hashref, or C<my @args = @_;> if you accept arguments from an array, or
C<my $args = $_[0] // [];> if you accept arguments from an arrayref) statement.
This should be one of the first things you write after your sub declaration
before you do anything else.

=item *

The third part (which is the part to validate function result and do stuffs
after performing the function) will be inserted right before the closing of the
subroutine.

=back

Currently regexes are used to parse the code so things might be rather fragile.

=for Pod::Coverage ^(munge_file|munge_files)$

=head1 RESTRICTIONS

There are some restrictions (hopefully not actually restricting) when writing
your code if you want to use this plugin.

=over

=item * Clash of variables

The generated wrapper code will declare some variables. You need to make sure
that the variables do not clash. This is rather simple: the variables used by
the wrapper code will all be prefixed with C<_w_> (e.g. C<$_w_res>) or C<_sahv_>
for variables generated by the L<Sah> schema compiler (e.g. C<$_sahv_dpath>).

=item * Variable used to accept arguments

Currently the wrapper internally will perform argument validation on
C<$args{ARGNAME}> variables, even if you accept arguments from a
hashref/array/arrayref. Thus:

If you accept arguments from a hash (the default), you need to put the arguments
to C<%args>, i.e.:

 my %args = @_;

You can then get the validated arguments e.g.:

 my $name = $args{name};
 my $addr = $args{address};
 ...

If you accept arguments from a hashref (i.e. C<< func({ arg1=>1, arg2=>2 }) >>):

 my $args = $_[0] // {};

If you accept arguments from an array (e.g. C<< func(1, 2) >>:

 my @args = @_;

If you accept arguments from an arrayref C<< func([1, 2]) >>:

 my $args = $_[0] // [];

=back

=head1 FAQ

=head2 Rationale for this plugin?

This plugin is an alternative to using L<Perinci::Sub::Wrapper> (PSW)
dynamically. During build, you generate the wrapper code and insert it to the
target code. The result is lower startup overhead (no need to generate the
wrapper code during runtime) and better guarantee that your wrapping code
(argument validation, etc) is always called when your subroutines are called,
even if your users do not use PSW and call your subroutines directly.

Another advantage/characteristic using this plugin is that, the wrapper code
does not introduce extra call level.

=head2 But why use PSW at all?

In short, adding L<Rinci> metadata to your subroutines allows various tools to
do useful stuffs, relieving you from coding those stuffs manually. Using L<Sah>
schema allows you to write validation code succintly, and gives you the ability
to automatically generate Perl/JavaScript/error messages from the schema.

PSW is one of the ways (currently the only way) to implement those
behaviours/functionalities.

=head2 But the generated code looks ugly!

Admittedly, yes. Wrapper-generated code is formatted as a single long line to
avoid modifying line numbers, which is desirable when debugging your modules. If
you don't want to compress everything as a single line, add C<debug=1> in your
C<dist.ini>.

=head2 How do I customize wrapping for my function

Two ways. You can either use C<wrap_args> in C<dist.ini> (see Synopsis) or add
an attribute in your function metadata:

 "x.dist.zilla.plugin.rinci.wrap.wrap_args" => { validate_args => 0 },

which will be merged and will override C<wrap_args> keys specified in
C<dist.ini>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Rinci-Wrap>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Dist-Zilla-Plugin-Rinci-Wrap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Rinci-Wrap>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

If you are only concerned with argument validation, you can take a look at:
L<Dist::Zilla::Plugin::Rinci::Validate>, L<Data::Sah::Manual::ParamsValidating>.

If you are only concerned with function return validation, you can take a look
at: L<Dist::Zilla::Plugin::Rinci::Validate>,
L<Data::Sah::Manual::ResultValidating>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
