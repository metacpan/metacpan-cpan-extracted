package MOP4Import::Base::Configure;
use MOP4Import::Declare -as_base, -fatal;

use Scalar::Util qw/weaken/;
use Carp;

use MOP4Import::Opts;
use MOP4Import::Types::Extend
  FieldSpec => [[fields => qw/weakref/]];

use constant DEBUG_WEAK => $ENV{DEBUG_MOP4IMPORT_WEAKREF};

our %FIELDS;

sub new {
  my MY $self = fields::new(shift);
  $self->configure(@_);
  $self->after_new;
  $self->configure_default;
  $self;
}

sub after_new {}

sub configure_default {
  (my MY $self) = @_;

  my $fields = MOP4Import::Declare::fields_hash($self);

  while ((my $name, my FieldSpec $spec) = each %$fields) {
    if (not defined $self->{$name} and defined $spec->{default}) {
      $self->{$name} = $self->can("default_$name")->($self);
    }
  }
}

sub configure {
  (my MY $self) = shift;

  my @args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

  my $fields = MOP4Import::Declare::fields_hash($self);

  my @setter;
  while (my ($key, $value) = splice @args, 0, 2) {
    unless (defined $key) {
      croak "Undefined option name for class ".ref($self);
    }
    next unless $key =~ m{^[A-Za-z]\w*\z};

    if (my $sub = $self->can("onconfigure_$key")) {
      push @setter, [$sub, $value];
    } elsif (exists $fields->{$key}) {
      $self->{$key} = $value;
    } else {
      croak "Unknown option for class ".ref($self).": ".$key;
    }
  }

  $_->[0]->($self, $_->[-1]) for @setter;

  $self;
}

sub declare___field_with_weakref {
  (my $myPack, my Opts $opts, my $callpack, my FieldSpec $fs, my ($k, $v)) = @_;

  $fs->{$k} = $v;

  if ($v) {
    my $name = $fs->{name};
    my $setter = "onconfigure_$name";
    print STDERR "# Declaring weakref $setter for $opts->{objpkg}.$name\n"
      if DEBUG_WEAK;
    *{MOP4Import::Util::globref($opts->{objpkg}, $setter)} = sub {
      print STDERR "# weaken $opts->{objpkg}.$name\n" if DEBUG_WEAK;
      weaken($_[0]->{$name} = $_[1]);
    };
  }
}


1;

__END__

=head1 NAME

MOP4Import::Base::Configure - OO Base class (based on MOP4Import)

=head1 SYNOPSIS

  package MyPSGIMiddlewareSample {
    use MOP4Import::Base::Configure -as_base
      , [fields =>

         , [app =>
             , doc => 'For Plack::Middleware standard conformance.']

         , [dbname =>
             , doc => 'Name of SQLite dbfile']
        ];

    use parent qw( Plack::Middleware );

    use DBI;

    sub call {
      (my MY $self, my $env) = @_;

      $env->{'myapp.dbh'} = DBI->connect("dbi:SQLite:dbname=$self->{dbname}");

      return $self->app->($env);
    }
  };

=head1 DESCRIPTION

MOP4Import::Base::Configure is a
L<MOP4Import|MOP4Import::Intro> family
and is my latest implementation of
L<Tk-like configure based object|MOP4Import::whyfields>
base classs. This class also inherits L<MOP4Import::Declare>,
so you can define your own C<declare_..> pragmas too.

=head1 METHODS

=head2 new (%opts | \%opts)
X<new>

Usual constructor. This passes given C<%opts> to L</configure>.

=head2 configure (%opts | \%opts)
X<configure>

General setter interface for public fields.
See also L<Tk style configure method|MOP4Import::whyfields/Tk-style-configure>.

=head2 configure_default ()
X<configure_default>

This fills undefined public fields with their default values.
Default values are obtained via C<default_FIELD> hook.
They are normally defined by
L<default|MOP4Import::Declare/declare___field_with_default> field spec.

=head1 HOOK METHODS

=head2 after_new
X<after_new>

This hook is called just after call of C<configure> in C<new>.

=head1 FIELD SPECs

For L<field spec|MOP4Import::Declare/FieldSpec>, you can also have
hook for field spec.

=head2 default => VALUE

This defines C<default_FIELDNAME> method with given VALUE.

=head2 weakref => 1

This generates set hook (onconfigure_FIELDNAME) wrapped with
L<Scalar::Util/weaken>.
