package Log::Message::Structured::Component::AttributesFilter;
use strict;
use warnings;

use MooseX::Role::Parameterized;
use namespace::autoclean;
use Moose::Util::TypeConstraints;

use MooseX::Types::Structured qw(Dict Optional);

use List::MoreUtils qw(notall any);

parameter filter => (
    isa => enum([qw(in out)]),
    default => sub { 'in' },
);

parameter type => (
    isa => enum([qw(public private)]),
    required => 0,
);

parameter name => (
    isa => 'RegexpRef|CodeRef',
    required => 0,
);

parameter value => (
    isa => 'RegexpRef|CodeRef',
    required => 0,
);

parameter custom => (
    isa => 'CodeRef',
    required => 0,
);

role {
    my ($p) = @_;
    my $in = $p->filter eq 'in';
    my @functions = $in ? sub { 1 } : sub { 0 } ;

    if (defined( my $r = $p->type)) {
        my $r = $p->type eq 'public' ? qr/^[^_]/ : qr/^_/;
        push @functions,
          sub { $_[0]->name =~ /$r/ }
      }
    if (defined(my $cond = $p->name)) {
        my $f = ref($cond) eq 'CODE'
          ? $cond : sub { /$cond/ };
        push @functions,
          sub { local $_ = $_[0]->name; $f->() }
    }
    if (defined (my $cond = $p->value)) {
        my $f = ref($cond) eq 'CODE'
          ? $cond : sub { /$cond/ };
        push @functions,
          sub { local $_ = $_[0]->get_value($_[1]); $f->() }
    }
    if (defined (my $custom = $p->custom)) {
        push @functions, $custom;
    }

    my $filter = $in
      ? # filtering in
      sub {
          my ($self, $hash) = @_;
          delete @{$hash}{
              map  { $_->name }
              grep { my $attr = $_; notall { $_->($attr, $self) } @functions
              } $self->meta->get_all_attributes
          };
          $hash;
      }
      : # filtering out
      sub {
          my ($self, $hash) = @_;
          delete @{$hash}{
              map  { $_->name }
              grep { my $attr = $_; any { $_->($attr, $self) } @functions
              } $self->meta->get_all_attributes
          };
          $hash;
      };

    around 'as_hash' => sub {
        my $orig = shift;
        my $self = shift;
        my $r = $filter->($self, $self->$orig(@_));
        $r;
    }

};

1;

=pod

=head1 NAME

Log::Message::Structured::Component::AttributesFilter

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with ('Log::Message::Structured',
          'Log::Message::Structured::Stringify::AsJSON',
          'Log::Message::Structured::Component::AttributesFilter' => {
             filter => 'out',
             name => qr /^foo/,
           });

    has [qw/ foo bar /] => ( is => 'ro', required => 1 );

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(Event->new( foo => "ONE MILLION", bar => "ONE BILLION" ));
    # Logs:
    {"__CLASS__":"MyLogEvent","foo":"ONE MILLION"}
    # note that bar is not included in the structure

=head1 DESCRIPTION

Augments the C<as_string> method provided by L<Log::Message::Structured> as a
parameterised Moose role.

=head1 PARAMETERS

=head1 filter

Enum : in, out. Specifies if the other criterias are to be used to filter in or out. Defaults to 'in'.

=head2 type

Enum : public, private. Filters on the attribute type

=head2 name

a RegexpRef or a CodeRef. Used to filter on the attribute name. The CodeRef will recieve the attribute's name in $_

=head2 value

a RegexpRef or a CodeRef. Used to filter on the attribute value. The CodeRef will recieve the attribute's value in $_

=head2 custom

a CodeRef. Used to do custom filtering. Will recieve the L<Class::MOP::Attribute> as first argument, and C<$self> as second argument.

=head1 AUTHOR AND COPYRIGHT

Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut

