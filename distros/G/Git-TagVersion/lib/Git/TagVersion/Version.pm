package Git::TagVersion::Version;

use Moose;

our $VERSION = '1.01'; # VERSION
# ABSTRACT: class for working with a version number

use Template;
use File::Slurp;
use Time::Piece;

use overload
  'cmp' => \&_cmp;

has 'digits' => (
  is => 'rw', isa => 'ArrayRef[Int]', default => sub { [] },
);

has 'seperator' => ( is => 'ro', isa => 'Str', default => '.' );

has 'tag' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'prev' => ( is => 'rw', isa => 'Maybe[Git::TagVersion::Version]' );

has 'repo' => ( is => 'ro', isa => 'Git::Wrapper', required => 1 );

has 'log' => (
  is => 'ro', isa => 'ArrayRef[Git::Wrapper::Log]', lazy => 1,
  default => sub {
    my $self = shift;
    my @log;

    my $revisions;
    if( defined $self->prev ) {
      $revisions = $self->prev->tag.'...'.$self->tag;
    } else {
      $revisions = $self->tag;
    }

    @log = $self->repo->log( $revisions );
    return \@log;
  },
);

has 'date' => (
  is => 'ro', isa => 'Maybe[Time::Piece]', lazy => 1,
  default => sub {
    my $self = shift;
    if( defined $self->log->[0] ) {
      my $date = $self->log->[0]->date;
      $date =~ s/^\w+ //;
      return Time::Piece->strptime(
        $date,
        "%b %d %H:%M:%S %Y %z",
      );
    }
    return;
  },
);
has 'author' => (
  is => 'ro', isa => 'Maybe[Str]', lazy => 1,
  default => sub {
    my $self = shift;
    if( defined $self->log->[0] ) {
      return( $self->log->[0]->author );
    }
    return;
  },
);

sub _cmp {
  my ( $obj_a, $obj_b ) = @_;

  my $i = 0;
  while(
      defined $obj_a->digits->[$i]
      && defined $obj_b->digits->[$i] ) {
    my $a = $obj_a->digits->[$i];
    my $b = $obj_b->digits->[$i];
    if( defined $a && ! defined $b ) {
      return 1;
    } elsif( ! defined ! $a && defined $b ) {
      return -1;
    } elsif( $a > $b ) {
      return 1;
    } elsif( $a < $b ) {
      return -1;
    }
    $i++
  }

  return 0;
}

sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    digits => [ @{$self->digits} ],
    repo => $self->repo,
  );
}

sub increment {
  my ( $self, $level ) = @_;
  my $i = -1 - $level;
  my @digits = @{$self->digits};

  my $value = $digits[$i];
  if( ! defined $value ) {
    die("cannot increment version at level $level");
  }

  $value++;
  splice @digits, $i, ($level + 1), ( $value, (0) x $level ) ;

  $self->digits( \@digits );
  return;
}

sub add_level {
  my ( $self, $level ) = @_;
  my @digits = @{$self->digits};
  foreach my $i (1..$level) {
    push( @digits, 0 );
  }
  $self->digits( \@digits );
  return;
}

sub as_string {
  my $self = shift;
  return( join( $self->seperator, @{$self->digits} ) );
}

sub parse_version {
  my ( $self, $version ) = @_;
  $version =~ s/^v//;

  my @digits = split(/\./, $version );

  foreach my $d ( @digits ) {
    if( $d !~ /^\d+$/ ) {
      die("$d is not numeric in version tag");
    }
  }

  $self->digits( \@digits );

  return;
}

has '_tt' => (
  is => 'ro', isa => 'Template', lazy => 1,
  default => sub {
   return Template->new(
     EVAL_PERL => 1,
   );
 },
);

has 'template_file' => ( is => 'ro', isa => 'Maybe[Str]' );

has '_template' => (
  is => 'ro', isa => 'Str', lazy => 1,
  default => sub {
    my $self = shift;
    if( $self->template_file ) {
      return read_file( $self->template_file );
    }
    return read_file( \*DATA );
  },
);

sub render {
  my ( $self, $style ) = @_;
  if( ! defined $style ) {
    $style = 'simple';
  }
  my $template = $self->_template;
  my $out;

  $self->_tt->process( \$template, {
    style => $style,
    self => $self,
  }, \$out )
    or die $self->_tt->error()."\n";

  return $out;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::Version - class for working with a version number

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
[% BLOCK markdown -%]
## Release [[% self.as_string %]] - [% self.date.strftime("%Y-%m-%d") %]
[% FOREACH log = self.log -%]
  - [% log.message.match('^(.*)\n').0 %]
[% END -%]

[% END -%]
[% BLOCK rpm -%]
* [% self.date.strftime("%a %b %d %Y") %] [% self.author %] [% self.as_string %]
[% FOREACH log = self.log -%]
- [% log.message.match('^(.*)\n').0 %]
[% END -%]

[% END -%]
[% BLOCK simple -%]
Changes in version [% self.as_string %]:
[% FOREACH log = self.log -%]
 * [% log.message.match('^(.*)\n').0 %]
[% END -%]

[% END -%]
[% INCLUDE $style -%]
