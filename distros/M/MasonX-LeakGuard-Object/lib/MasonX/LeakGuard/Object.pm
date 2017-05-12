package MasonX::LeakGuard::Object;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.03';

use base qw(HTML::Mason::Plugin);

use Devel::LeakGuard::Object::State;
use Data::Dumper;

our %BEEN_IN;

our %OPTIONS;

=head1 NAME

MasonX::LeakGuard::Object - report memory leaks (objects) per request

=head1 SYNOPSIS

    use MasonX::LeakGuard::Object;
    %MasonX::LeakGuard::Object::OPTIONS = (
        exclude => [
            'utf8',
            'HTML::Mason::*',
            'Devel::StackTrace',
        ],
        hide_arguments => [
            'pass', 'password',
        ],
    );
    my @MasonParameters = (
        ...
        plugins => [qw(MasonX::LeakGuard::Object)],
    );

=head1 DESCRIPTION

This is plugin for L<HTML::Mason> based applications that helps you
find memory leaks in OO code. It uses L<Devel::LeakGuard::Object>
framework for that.

=head1 OPTIONS

It's possible to use all options leakguard function in
L<Devel::LeakGuard::Object> supports. Look at L</SYNOPSIS> for example.

Some additional options are supported.

=head2 on_leak

on_leak option can be used to customize report or redirect to custom
log, for example:

    %MasonX::LeakGuard::Object::OPTIONS = (
        on_leak => sub {
            my ($report, %args) = @_;
            MyApp->logger->error( $args{'message'} );
        },
    );

First argument is the report structure (read more on it in 
L<Devel::LeakGuard::Object>). To make life easier more data
is passed into your function as a hash. The hash contains:

=over 4

=item formatted - formatted report, a text table.

=item message - formatted default message containg description,
request path, request arguments and report. For example:

    Leak(s) found after request to '/index.html' with $ARGS1 = [
               'argument',
               'value',
             ];
    Leaked objects:
      Class          Before  After  Delta
      MyApp::Class        0      1      1

=item path - request path.

=item arguments - request arguments, array reference.

=back

=head2 hide_arguments

It's possible to specify list of arguments names to hide from
reports, for example:

    %MasonX::LeakGuard::Object::OPTIONS = (
        hide_arguments => [
            'pass', 'password',
        ],
    );

=head1 FALSE POSITIVES

It's possible that false positives are reported, for example if
a compontent has ONCE block where you cache some values on first
request. Most caches will generate false positive reports, but
it's possible to use options of L<function leakguard in Devel::LeakGuard::Object|Devel::LeakGuard::Object/leakguard>. Look at L</SYNOPSIS> for
example and L</OPTIONS> for additional details.

To avoid many false positives the module as well B<ignores> first
request to a path.

Sure it doesn't protect you from all cases.

=cut

sub start_request_hook {
    my ($self, $context) = @_;

    my $path = $context->request->request_comp->path;
    unless ( $BEEN_IN{ $path } ) {
        $BEEN_IN{ $path } = 1;
        return;
    }

    my @request_args = @{ scalar $context->args };
    my $base_handler = sub {
        my $report = shift;
        my $formatted = Devel::LeakGuard::Object::State->_fmt_report(
            $report
        );
        if ( my $hide = $OPTIONS{'hide_arguments'} ) {
            foreach ( my $i = 0; $i < @request_args; $i+=2 ) {
                my $name = $request_args[$i];
                next unless grep $name eq $_, @$hide;

                splice @request_args, $i, 2;
                $i -= 2;
            }
        }
        local $Data::Dumper::Varname = 'ARGS';
        my $msg =
            "Leak(s) found after request to '$path'"
            ." with ". Dumper(\@request_args)
            ."Leaked objects:\n". $formatted;
        return {
            report    => $report,
            formatted => $formatted,
            message   => $msg,
            path      => $path,
            arguments => \@request_args,
        };
    };

    my $leak_handler;
    if ( $OPTIONS{'on_leak'} ) {
        if ( ref $OPTIONS{'on_leak'} eq 'CODE' ) {
            $leak_handler = sub {
                my $tmp = $base_handler->(@_);
                return $OPTIONS{'on_leak'}->(
                    delete $tmp->{'report'},
                    %$tmp,
                );
            };
        } elsif ( $OPTIONS{'on_leak'} eq 'die' ) {
            $leak_handler = sub { die $base_handler->(@_)->{'message'} };
        } elsif ( $OPTIONS{'on_leak'} eq 'warn' ) {
            $leak_handler = sub { warn $base_handler->(@_)->{'message'} };
        } else {
            die "Incorrect on_leak option";
        }
    } else {
        $leak_handler = sub { warn $base_handler->(@_)->{'message'} };
    }

    $self->{'state'} = Devel::LeakGuard::Object::State->new(
        only    => $OPTIONS{'only'},
        exclude => $OPTIONS{'exclude'},
        expect  => $OPTIONS{'expect'},
        on_leak => $leak_handler,
    );
}

sub end_request_hook {
    my ($self, $context) = @_;

    my $state = delete $self->{'state'}
        or return;
    $state->done;
}

1;

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

-cut
