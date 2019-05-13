package Mail::STS::Policy;

use Moose;

our $VERSION = '0.04'; # VERSION
# ABSTRACT: class to parse and generate RFC8461 policies


has 'version' => (
  is => 'rw',
  isa => 'Str',
  default => 'STSv1',
);

has 'mode' => (
  is => 'rw',
  isa => 'Str',
  default => 'none',
);

has 'max_age' => (
  is => 'rw',
  isa => 'Maybe[Int]',
);

has 'mx' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [] },
  traits => ['Array'],
  handles => {
    'add_mx' => 'push',
    'clear_mx' => 'clear',
  },
);


sub new_from_string {
  my ($class, $string) = @_;
	my $self = $class->new;
  $self->parse($string);
  return $self;
}


sub parse {
	my ($self, $string) = @_;
	my @lines = split(/[\r\n]+/, $string);
  my $ln = 0;
  $self->clear_mx;

  while( my $line = shift(@lines) ) {
    $ln++;
    $line =~ s/[\r\n]*$//;
    my ($key, $value) = split(/\s*:\s+/, $line, 2);
    unless(defined $key && defined $value) {
      die("invalid syntax on line ${ln}");
    }
    if($key eq 'version') {
      unless($value eq 'STSv1') {
        die('only STSv1 version of policy is supported');
      }
      $self->version($value);
      next;
    } elsif($key eq 'mode') {
      unless($value =~ /^(testing|enforce|none)$/) {
        die("unsupported mode on line ${ln}");
      }
      $self->mode($value);
      next;
    } elsif($key eq 'max_age') {
      unless($value =~ /^(\d+)$/) {
        die("max_age must be an integer on line ${ln}");
      }
      $self->max_age(int $value);
      next;
    } elsif($key eq 'mx') {
      unless($value =~ /^(\*\.)?[0-9a-zA-Z\-]+(\.[0-9a-zA-Z\-]+)*$/) {
        die("invalid mx entry on line ${ln}");
      }
      $self->add_mx($value);
      next;
    }
    die("unknown key ${key} in policy on line ${line}");
  }
}


sub as_hash {
  my $self = shift;
  return {
    'version' => $self->version,
    'mode' => $self->mode,
    'max_age' => $self->max_age,
    'mx' => $self->mx,
  };
}


sub as_string {
  my $self = shift;
  my $hash = $self->as_hash;
  return join('', map {
    _sprint_key_value($_, $hash->{$_});
  } 'version', 'mode', 'max_age', 'mx');
}

sub _sprint_key_value {
  my ($key, $value) = @_;
  return '' unless defined $value;
  unless(ref $value) {
    return("${key}: ${value}\n");
  }
  if(ref($value) eq 'ARRAY') {
    return join('', map { "${key}: $_\n" } @$value);
  }
  die('invalid data type for policy');
}


sub match_mx {
  my ($self, $host) = @_;
  foreach my $mx (@{$self->mx}) {
    if($host eq $mx) {
      return 1;
    }
    if(my ($domain) = $mx =~ /^\*\.(.+)$/) {
      return 1 if $host eq $domain;
      my $suffix = ".${domain}";
      my $suffix_len = length($suffix);
      return 1 if substr($host, -$suffix_len) eq $suffix;
    }
  }
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::STS::Policy - class to parse and generate RFC8461 policies

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # generate a policy
  my $policy = Mail::STS::Policy->new(
    mode => 'enforce',
    max_age => 604800,
    mx => [ 'mail.example.com' ],
  );
  # setters
  $policy->mode('testing');
  $policy->add_mx('mail.example.com');
  print $policy->as_string;

  # parse existing policy
  my $policy = Mail::STS::Policy->new_from_string($string);
  # access values
  $policy->mode;
  # 'enforce'
  $policy->mx;
  # [ 'mail.example.com' ]

  # check if a host is in there
  $policy->match_mx('mail.blablub.de') or die;

=head1 ATTRIBUTES

=head2 version (default: 'STSv1')

Currently always version 'STSv1'.

=head2 mode (default: 'none')

Get/set mode of policy.

=head2 max_age (default: undef)

Get/set max_age for policy caching.

=head2 mx (default: [])

Array reference to array of mx hosts.

=head1 METHODS

=head2 new_from_string($string)

Constructor for creating a new policy object from a policy string.

Internally creates objects by calling new() and execute parse() on it.

=head2 parse($string)

Parses values from $string to values in the object overwriting
and clearing all existing values.

Will die() on parsing error.

=head2 as_hash

Returns a hash reference containing policy data.

  $policy->as_hash
  # {
  #   'version' => 'STSv1',
  #   'mode' => 'enforce',
  #   'max_age' => 3600,
  #   'mx' => [ 'mx.example.com', ... ],
  # }

=head2 as_string

Outputs the object as a RFC8461 policy document.

=head2 match_mx($host)

Returns if the policy matches $host.

  $policy->match_mx('mail.example.com') or die;

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
