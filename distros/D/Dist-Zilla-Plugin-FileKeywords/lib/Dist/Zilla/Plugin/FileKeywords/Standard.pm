package Dist::Zilla::Plugin::FileKeywords::Standard;
# ABSTRACT: Plugin providing a Standard set of FileKeywords

use Moose;
use Moose::Autobox;

BEGIN
  { our $VERSION = substr '$$Version: 0.02 $$', 11, -3; }

# List of keywords to include/exclude from
# those provided. Not implemented yet.
has import =>
  ( is	     => 'ro'
  , isa	     => 'ArrayRef'
  );

has zilla    =>
  ( is	     => 'ro'
  , isa	     => 'Dist::Zilla'
  , required => 1
  , weak_ref => 1
  );

has keyhash =>
  ( is	    => 'ro'
  , isa     => 'HashRef'
  , default => sub
      { { Version      => \&_value_version
	, Distribution => \&_value_dist
	};
      }
  );


sub keylist{ return [keys %{ $_[0]->keyhash }] }

sub value
  { my ($self,$file,$key) = @_;
    my $hashref		  = $self->keyhash;
    my $coderef		  = $$hashref{$key};

    return $coderef->($self,$file,$key);
  }

# Private Methods
sub _value_version
  { my ($self) = @_;

    return $self->zilla->version;
  }

sub _value_dist
  { my ($self,$file) = @_;

    return $self->zilla->name;
  }

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::FileKeywords::Standard - Standard Keywords plugin.

=head1 VERSION

version 1.0

=head1 DESCRIPTION

This plugin is a plugin for the FileKeywords file_munger plugin. It
defines a few keywords that are common to all distributions.

=head1 KEYWORDS

=over

=item B<Version>

The current version number, as stored in C<<zilla->version>>.

=item B<Distribution>

The current distribution name, as stored in C<<zilla->name>>.

=back

=head1 AUTHOR

Stirling Westrup <swestrup@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stirling Westrup.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

