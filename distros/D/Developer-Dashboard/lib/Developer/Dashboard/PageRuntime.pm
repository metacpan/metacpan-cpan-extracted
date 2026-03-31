package Developer::Dashboard::PageRuntime;
$Developer::Dashboard::PageRuntime::VERSION = '0.72';
use strict;
use warnings;

use Capture::Tiny qw(capture);
use DataHelper qw(j je);
use Folder ();
use Template;
use Zipper qw(Ajax acmdx zip unzip);

my $SANDPIT_SEQ = 0;

# new(%args)
# Constructs the legacy-style page runtime used by browser-rendered bookmarks.
# Input: optional path registry and folder alias data.
# Output: Developer::Dashboard::PageRuntime object.
sub new {
    my ( $class, %args ) = @_;
    return bless {
        files   => $args{files},
        paths   => $args{paths},
        aliases => $args{aliases} || {},
    }, $class;
}

# prepare_page(%args)
# Executes legacy CODE blocks, then applies Template Toolkit rendering.
# Input: page document, source kind, and runtime context hash.
# Output: updated page document object.
sub prepare_page {
    my ( $self, %args ) = @_;
    $self = __PACKAGE__->new if !ref($self);
    my $page   = $args{page} || die 'Missing page';
    my $source = $args{source} || 'saved';
    my $runtime_context = $args{runtime_context} || {};

    my $runtime = $self->run_code_blocks(
        page            => $page,
        source          => $source,
        runtime_context => $runtime_context,
    );

    $page->{meta}{runtime_outputs} = $runtime->{outputs};
    $page->{meta}{runtime_errors}  = $runtime->{errors};
    $self->_render_templates(
        page            => $page,
        runtime_context => $runtime_context,
    );
    return $page;
}

# run_code_blocks(%args)
# Executes CODE sections and returns captured stdout/stderr display chunks.
# Input: page document, source kind, and runtime context hash.
# Output: hash reference with outputs and errors arrays.
sub run_code_blocks {
    my ( $self, %args ) = @_;
    $self = __PACKAGE__->new if !ref($self);
    my $page   = $args{page} || die 'Missing page';
    my $codes  = $page->as_hash->{meta}{codes} || [];
    my $state  = $page->{state} || {};

    return { outputs => [], errors => [] } if ref($codes) ne 'ARRAY' || !@$codes;

    my @outputs;
    my @errors;
    my $sandpit = $self->_new_sandpit(
        state           => $state,
        runtime_context => $args{runtime_context} || {},
    );

    eval {
        CODE:
        for my $block (@$codes) {
            next if ref($block) ne 'HASH';
            my $code = $block->{body} // '';
            next if $code eq '';

            my $result = eval {
                $self->_run_single_block(
                    code            => $code,
                    sandpit         => $sandpit,
                    state           => $state,
                    runtime_context => $args{runtime_context} || {},
                );
            };

            if ($@) {
                my $error = "$@";
                if ( $error =~ /^__DD_HIDE__/ ) {
                    next CODE;
                }
                if ( $error =~ /^__DD_STOP__(?:\n(.*))?/s ) {
                    push @errors, $1 if defined $1 && $1 ne '';
                    last CODE;
                }
                push @errors, $error;
                last CODE;
            }

            if ( ref( $result->{merge} ) eq 'HASH' ) {
                $page->merge_state( $result->{merge} );
                $state = $page->{state};
            }

            if ( ref( $result->{returns} ) eq 'ARRAY' ) {
                for my $value ( @{ $result->{returns} } ) {
                    if ( ref($value) eq 'HASH' ) {
                        $page->merge_state($value);
                        $state = $page->{state};
                    }
                    next if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
                    push @outputs, $self->_runtime_value_text($value);
                }
            }

            my $stdout = defined $result->{stdout} ? $result->{stdout} : '';
            my $stderr = defined $result->{stderr} ? $result->{stderr} : '';

            push @outputs, $stdout if $stdout ne '';
            push @errors, $stderr if $stderr ne '';
        }
        1;
    };

    $self->_destroy_sandpit($sandpit);

    return {
        outputs => \@outputs,
        errors  => \@errors,
    };
}

# _runtime_value_text($value)
# Serializes a returned runtime value for in-page output after CODE execution.
# Input: returned Perl scalar reference from a CODE block.
# Output: Perl-ish text string.
sub _runtime_value_text {
    my ( $self, $value ) = @_;
    return '' if !defined $value;
    return '' if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return _runtime_legacy_value($value);
}

# _render_templates(%args)
# Processes legacy HTML and FORM.TT sections through Template Toolkit.
# Input: page document and runtime context hash.
# Output: none; mutates page layout in place.
sub _render_templates {
    my ( $self, %args ) = @_;
    my $page = $args{page} || die 'Missing page';
    my $layout = $page->{layout} || {};
    my $state  = $page->{state}  || {};

    my $system = $self->_system_context(%args);
    my $tt = Template->new(
        {
            EVAL_PERL   => 1,
            INCLUDE_PATH => $self->{paths} ? $self->{paths}->dashboards_root : '.',
        }
    );

    for my $field ( qw(body form_tt) ) {
        my $template = $layout->{$field};
        next if !defined $template || $template eq '';
        my $rendered = '';
        my $page_data = $page->as_hash;
        my $ok = $tt->process(
            \$template,
            {
                app    => $page,
                parts  => $page,
                page   => $page_data,
                stash  => $state,
                id     => $page_data->{id},
                title  => $page_data->{title},
                description => $page_data->{description},
                mode   => $page_data->{mode},
                icon   => $page_data->{icon},
                ENV    => \%ENV,
                SYSTEM => $system,
                env    => \%ENV,
                func   => sub { return '' },
                method => sub {
                    my ( $class, $method, @rest ) = @_;
                    return '' if !$class || !$method || !$class->can($method);
                    return $class->$method(@rest);
                },
                eval => sub {
                    my ($code) = @_;
                    my $result = $self->_run_single_block(
                        code            => $code,
                        state           => $state,
                        runtime_context => $args{runtime_context} || {},
                    );
                    die $result->{stderr} if defined $result->{stderr} && $result->{stderr} ne '';
                    return $result->{stdout};
                },
                %$state,
            },
            \$rendered,
        );

        if ($ok) {
            $page->{layout}{$field} = $rendered;
            next;
        }

        push @{ $page->{meta}{runtime_errors} ||= [] }, $tt->error;
    }

    if ( defined $layout->{form} && $layout->{form} ne '' ) {
        my $form = $layout->{form};
        $form =~ s/\[\%([\w\_]+)\%\]/_escape_html($page->{$1})/ge;
        $form =~ s/\[\#([\w\_]+)\#\]/_escape_html($state->{$1})/ge;
        if ( ref( $args{runtime_context}{params} ) eq 'HASH' ) {
            $form =~ s/\{\{([\w\_\-]+)\}\}/_escape_html($args{runtime_context}{params}{$1})/ge;
        }
        $page->{layout}{form} = $form;
    }
}

# _system_context(%args)
# Builds the generic SYSTEM hash exposed to bookmark Template Toolkit rendering.
# Input: runtime context hash.
# Output: hash reference of generic runtime/system values.
sub _system_context {
    my ( $self, %args ) = @_;
    return {
        cwd    => $args{runtime_context}{cwd} || '.',
        source => $args{source} || '',
        params => $args{runtime_context}{params} || {},
    };
}

# _run_single_block(%args)
# Executes one CODE block inside the active legacy sandpit package.
# Input: Perl code string, mutable stash hash, runtime context hash, and optional sandpit hash.
# Output: hash reference with stdout, stderr, returns, and merged stash.
sub _run_single_block {
    my ( $self, %args ) = @_;
    my $code            = $args{code} // '';
    my $state           = $args{state} || {};
    my $runtime         = $args{runtime_context} || {};
    my $sandpit         = $args{sandpit};
    my $destroy_sandpit = !$sandpit ? 1 : 0;

    Folder->configure(
        paths   => $self->{paths},
        aliases => $self->{aliases},
    );
    $sandpit ||= $self->_new_sandpit(
        state           => $state,
        runtime_context => $runtime,
    );

    my $package = $sandpit->{package} || die 'Missing sandpit package';
    my $wrapped_code = $self->_code_header($state) . $code;
    my @returns;
    my ( $stdout, $stderr, $exit_code ) = capture {
        @returns = $package->__run_code($wrapped_code);
        return $?;
    };
    my @errors = $package->__errors();
    if (@errors) {
        my $error = join '', grep { defined $_ && $_ ne '' } @errors;
        $self->_destroy_sandpit($sandpit) if $destroy_sandpit;
        die $error if $error ne '';
    }

    $self->_destroy_sandpit($sandpit) if $destroy_sandpit;

    return {
        stdout  => $stdout,
        stderr  => $stderr,
        returns => \@returns,
        merge   => $state,
    };
}

# _code_header($state)
# Builds the legacy lexical stash header injected before each CODE block.
# Input: mutable stash hash reference.
# Output: Perl source string.
sub _code_header {
    my ( $self, $state ) = @_;
    $state ||= {};

    my @keys = grep { /^[A-Za-z_][A-Za-z0-9_]*$/ } sort keys %$state;
    return '' if !@keys;

    my $header = sprintf 'my (%s) = @{ $stash }{qw(%s)};' . "\n",
      join( ', ', map { '$' . $_ } @keys ),
      join( ' ', @keys );
    $header .= sprintf 'my (%s) = map { \\$stash->{$_} } qw(%s);' . "\n",
      join( ', ', map { '$' . $_ . '_r' } @keys ),
      join( ' ', @keys );
    return $header;
}

# _new_sandpit(%args)
# Creates one throwaway package used across CODE blocks for a single page run.
# Input: mutable stash hash reference and runtime context hash.
# Output: hash reference containing the generated package name.
sub _new_sandpit {
    my ( $self, %args ) = @_;
    my $package = sprintf 'Developer::Dashboard::Sandpit::%d::%d::%d', $$, time, ++$SANDPIT_SEQ;
    $package =~ s/[^A-Za-z0-9:]/_/g;

    my $compiled = <<"PERL";
package $package;
use strict;
use warnings;
use DataHelper qw(j je);
use Zipper qw(Ajax acmdx zip unzip);

our \$stash = {};
our \$runtime = {};
our \@errors = ();

sub __add_error {
    push \@errors, grep { defined \$_ && \$_ ne '' } \@_;
}

sub __errors {
    my \@copy = \@errors;
    \@errors = ();
    return \@copy;
}

sub stash {
    my (\$input) = \@_;
    die "no input" if !defined \$input;
    if (ref(\$input) eq 'HASH') {
        \@{\$stash}{keys %\$input} = values %\$input;
        return \$input;
    }
    return \$stash->{\$input};
}

sub hide {
    my (\$input) = \@_;
    stash(\$input) if ref(\$input) eq 'HASH';
    return "__DD_HIDE__";
}

sub void {
    my (\$input) = \@_;
    stash(\$input) if defined \$input;
    return;
}

sub stop {
    my (\$message) = \@_;
    die "__DD_STOP__\\n" . (defined \$message ? \$message : '');
}

sub params {
    return \$runtime->{params} || {};
}

sub __initial_context {
    my (\$class, \$next_stash, \$next_runtime) = \@_;
    \$stash = \$next_stash || {};
    \$runtime = \$next_runtime || {};
    \@errors = ();
    return 1;
}

sub __run_code {
    my (\$class, \$code) = \@_;
    my \@result = eval "{\$code}";
    __add_error(\$@) if \$@;
    return \@result;
}

1;
PERL
    my $ok = eval $compiled;
    die "Unable to setup sandpit $@\n" if !$ok;

    $package->__initial_context(
        $args{state} || {},
        $args{runtime_context} || {},
    );

    return { package => $package };
}

# _destroy_sandpit($sandpit)
# Clears the generated sandpit package to avoid runtime symbol leakage across page runs.
# Input: sandpit hash reference created by _new_sandpit.
# Output: none.
sub _destroy_sandpit {
    my ( $self, $sandpit ) = @_;
    return if ref($sandpit) ne 'HASH' || !$sandpit->{package};
    my $stash = $sandpit->{package};
    no strict 'refs';
    %{"${stash}::"} = ();
    return;
}

# _escape_html($text)
# Escapes scalar text for safe HTML interpolation in legacy FORM blocks.
# Input: text scalar.
# Output: escaped text scalar.
sub _escape_html {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    return $text;
}

# _runtime_legacy_value($value)
# Serializes a Perl scalar, array, or hash into a Perl-ish runtime text form.
# Input: scalar, array reference, or hash reference.
# Output: Perl-ish text string.
sub _runtime_legacy_value {
    my ($value) = @_;
    return 'undef' if !defined $value;
    if ( ref($value) eq 'ARRAY' ) {
        return "[\n  " . join( ",\n  ", map { _runtime_legacy_value($_) } @$value ) . "\n]";
    }
    if ( ref($value) eq 'HASH' ) {
        return "{\n  " . join( ",\n  ", map { sprintf "%s => %s", $_, _runtime_legacy_value( $value->{$_} ) } sort keys %$value ) . "\n}";
    }
    return $value =~ /\A-?\d+(?:\.\d+)?\z/ ? $value : "'" . _runtime_legacy_quote($value) . "'";
}

# _runtime_legacy_quote($text)
# Escapes a scalar string for runtime Perl-ish single-quoted output.
# Input: text string.
# Output: escaped string.
sub _runtime_legacy_quote {
    my ($text) = @_;
    $text =~ s/\\/\\\\/g;
    $text =~ s/'/\\'/g;
    return $text;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PageRuntime - legacy bookmark renderer and CODE executor

=head1 SYNOPSIS

  my $runtime = Developer::Dashboard::PageRuntime->new(paths => $paths);
  $runtime->prepare_page(page => $page, source => 'saved');

=head1 DESCRIPTION

This module applies Template Toolkit rendering to bookmark HTML and executes
legacy C<CODE*> blocks while capturing STDOUT and STDERR for in-page display.

=head1 METHODS

=head2 new, prepare_page, run_code_blocks

Construct the runtime, render bookmark templates, and execute CODE blocks.

=cut
