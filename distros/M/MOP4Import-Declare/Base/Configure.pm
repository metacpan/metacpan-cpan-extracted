package MOP4Import::Base::Configure;
use MOP4Import::Declare -as_base, -fatal;

use Scalar::Util qw/weaken/;
use Carp;

use MOP4Import::Opts;
use MOP4Import::Types::Extend
  FieldSpec => [[fields => qw/weakref/]];

use constant DEBUG_WEAK => $ENV{DEBUG_MOP4IMPORT_WEAKREF};

our %FIELDS;

#---------

sub new :method {
  my MY $self = fields::new(shift);
  $self->configure(@_);
  $self->before_configure_default;
  $self->after_new;
  $self->configure_default;
  $self->after_configure_default;
  $self;
}

sub before_configure_default :method {}
sub after_new {}; # Should be deprecated near future.
sub after_configure_default :method {}

sub configure_default :method {
  (my MY $self, my $target) = @_;

  $target //= $self;

  my $fields = MOP4Import::Declare::fields_hash($self);

  while ((my $name, my FieldSpec $spec) = each %$fields) {
    if (not defined $target->{$name} and defined $spec->{default}) {
      $target->{$name} = $self->can("default_$name")->($self);
    }
  }

  $target;
}

sub configure :method {
  (my MY $self) = shift;

  my @args = do {
    if (@_ != 1) {
      @_;
    } elsif (ref $_[0] eq 'HASH') {
      %{$_[0]}
    } elsif (my $sub = UNIVERSAL::can($_[0], "cf_configs")) {
      # Shallow copy via cf_configs()
      $sub->($_[0]);
    } else {
      Carp::croak "Unknown argument! ".MOP4Import::Util::terse_dump($_[0]);
    }
  };

  my $fields = MOP4Import::Declare::fields_hash($self);

  my @setter;
  while (my ($key, $value) = splice @args, 0, 2) {
    unless (defined $key) {
      croak "Undefined option name for class ".ref($self);
    }

    if ($key =~ m{^_}) {
      croak "Private option is prohibited for class ".ref($self).": $key";
    }

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

sub cget :method {
  my ($self, $key, $default) = @_;
  $key =~ s/^--//;
  my $fields = MOP4Import::Declare::fields_hash($self);
  if (not exists $fields->{$key}) {
    confess "No such option: $key"
  }
  $self->{$key} // $default;
}

sub declare___field_with_weakref :MetaOnly {
  (my $myPack, my Opts $opts, my FieldSpec $fs, my ($k, $v)) = m4i_args(@_);

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

sub cf_configs :method {
  (my MY $self, my (%opts)) = @_;
  my $all = delete $opts{all};
  if (keys %opts) {
    Carp::croak "Unknown option for cf_configs: ".join(", ", sort keys %opts);
  }
  my $fields = MOP4Import::Util::fields_hash($self);
  my @result;
  foreach my $key ($self->cf_public_fields) {
    defined (my $val = $self->{$key})
      or next;
    my FieldSpec $spec = $fields->{$key};
    if (not $all
          and defined $spec->{default} and $val eq $spec->{default}) {
      next;
    }
    push @result, $key, MOP4Import::Util::shallow_copy($val);
  }
  @result;
}

sub cf_public_fields :method {
  my $obj_or_class = shift;
  my $fields = MOP4Import::Util::fields_hash($obj_or_class);
  sort grep {/^[a-z]/i} keys %$fields;
}

1;

__END__

=head1 NAME

MOP4Import::Base::Configure - Base class with configure() interface for fields

=head1 SYNOPSIS

  package MyMetaCPAN {
     
     use MOP4Import::Base::Configure -as_base
       , [fields =>
          [baseurl => default => 'https://fastapi.metacpan.org/v1'],
        ]
       ;
     
     sub get {
       (my MY $self, my $entry) = @_;
       $self->furl_get("$self->{baseurl}$entry");
     }
   }
  
  #
  
  my $obj = MyMetaCPAN->new;
  print $obj->baseurl; # => https://fastapi.metacpan.org/v1
  $obj->get("/author/someone");

  $obj = MyMetaCPAN->new(baseurl => 'http://localhost:8000');
  # $obj = MyMetaCPAN->new({baseurl => 'http://localhost:8000'});
  # $obj->configure(baseurl => 'http://localhost:8000');

  print $obj->baseurl; # => 'http://localhost:8000'
  $obj->get("/author/someone");


=head1 DESCRIPTION

MOP4Import::Base::Configure is a minimalistic base class
for L<fields> based OO with support of Tk-like new/configure interface,
automatic getter generation and default value initialization.

This class also inherits L<MOP4Import::Declare>,
so you can define your own C<declare_..> pragmas too.

=head1 METHODS

=head2 new (%opts | \%opts)
X<new>

Usual constructor. This passes given C<%opts> to L</configure>.
Actual implementation is following:

  sub new :method {
    my MY $self = fields::new(shift);
    $self->configure(@_);
    $self->before_configure_default;
    $self->after_new; # Note: deprecated.
    $self->configure_default;
    $self->after_configure_default;
    $self;
  }

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

=head2 before_configure_default

This hook is called after configure and just before configure_default.
This is useful to change behavior whether specific option is given or not.

=head2 after_configure_default

This hook is called after configure_default.
This is useful to compute all fields are filled with default values.

=head2 after_new (deprecated)
X<after_new>

This method is called just before configure_default.

=head1 FIELD SPECs

For L<field spec|MOP4Import::Declare/FieldSpec>, you can also have
hook for field spec.

=head2 default => VALUE

This defines C<default_FIELDNAME> method with given VALUE.

=head2 weakref => 1

This generates set hook (onconfigure_FIELDNAME) wrapped with
L<Scalar::Util/weaken>.

=head2 json_type => STRING | Cpanel::JSON::XS::Type

To be documented...

=head1 SEE ALSO

L<MOP4Import::Declare>

=head1 AUTHOR

Kobayashi, Hiroaki E<lt>hkoba@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
