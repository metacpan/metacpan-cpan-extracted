package Message::Passing::Role::CLIComponent;
use strict;
use warnings;
use Package::Variant
    importing => ['Moo::Role'],
    subs => [ qw(has around before after with) ];
use MooX::Options;
use MooX::Types::MooseLike::Base qw/ Str /;
use JSON::MaybeXS ();
use Try::Tiny qw/ try /;

sub make_variant {
    my ($class, $target_package, %arguments) = @_;
    my $p = shift;

    my $name = $arguments{name};
    my $has_default = exists $arguments{default};
    my $default = $has_default ? $arguments{default} : undef;

    option "$name" => (
        isa => Str,
        is => 'ro',
#       required => "$has_default" ? 0 : 1,
        "$has_default" ? ( default => sub { "$default" } ) : (),
        format => 's',
    );

    option "${name}_options" => (
        is => 'ro',
        default => sub { {} },
        isa => sub { ref($_[0]) eq 'HASH' },
        coerce => sub {
            my $str = shift;
            if (! ref $str) {
                try {
                    $str = JSON::MaybeXS->new(relaxed => 1)->decode($str)
                };
            }
            $str;
        },
        format => 's',
    );
}

1;

=head1 NAME

Message::Passing::Role::CLIComponent - Package::Variant providing 'foo' and 'foo_options' attributes

=head1 SYNOPSIS

    package My::Message::Passing::Script;
    use Moo;
    use MooX::Options;
    use Message::Passing::Role::CLIComponent;
    use Message::Passing::DSL;
    use namespace::clean -except => 'meta';

    with
        CLIComponent( name => 'input', default => 'STDIN' ),
        'Message::Passing::Role::Script';

    sub build_chain {
        my $self = shift;
        message_chain {
            input example => ( %{ $self->input_options }, output_to => 'test_out', class => $self->input, );
            output test_out => ( ... );
        };
    }

    __PACKAGE__->start unless caller;
    1;

=head1 DESCRIPTION

A L<Package::Variant> role producer, which is used to provide a pair of attributes for name/options
as per the L<message-pass> script.

=head1 ROLE PARAMETERS

=head2 name

The name of the main attribute. An additional attribute called C<< "${name}_options" >> will also be added,
which coerces a hashref from JSON.

=head2 default

A default value for the main attribute. If this is not supplied, than the attribute will be required.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut