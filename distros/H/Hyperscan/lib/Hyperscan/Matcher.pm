package Hyperscan::Matcher;
$Hyperscan::Matcher::VERSION = '0.03';
# ABSTRACT: high level matcher class

use strict;
use warnings;

use Carp;
use re qw(regexp_pattern);

use Hyperscan;
use Hyperscan::Database;
use Hyperscan::Util qw(re_flags_to_hs_flags);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize {
    my $self = shift;

    my $specs = shift;
    my %args  = @_;

    my $literal = defined $args{literal} ? $args{literal} : 0;
    my $default_flags =
      defined $args{default_flags}
      ? $args{default_flags}
      : Hyperscan::HS_FLAG_SOM_LEFTMOST;

    my $mode = defined $args{mode} ? $args{mode} : "block";

    $self->{mode} = $mode;

    $mode =
        $mode eq "block" ? Hyperscan::HS_MODE_BLOCK
      : $mode eq "stream"
      ? Hyperscan::HS_MODE_STREAM | Hyperscan::HS_MODE_SOM_HORIZON_LARGE
      : $mode eq "vectored" ? Hyperscan::HS_MODE_VECTORED
      :                       croak "unknown mode $mode";

    my @expressions;
    my @flags;
    my @ids;
    my @ext;

    for ( my $id = 0 ; $id <= $#{$specs} ; $id++ ) {
        my $spec = $specs->[$id];
        if ( ref $spec eq "" ) {
            push @expressions, $spec;
            push @flags,       $default_flags;
            push @ids,         $id;
            push @ext,         undef;
        }
        elsif ( ref $spec eq "REGEXP" || ref $spec eq "Regexp" ) {
            my ( $pat, $mod ) = regexp_pattern($spec);

            my $flag = $default_flags;
            $flag |= re_flags_to_hs_flags($mod);

            push @expressions, $pat;
            push @flags,       $flag;
            push @ids,         $id;
            push @ext,         undef;
        }
        elsif ( ref $spec eq "ARRAY" ) {
            my $pat = shift @{$spec};

            my $flag = $default_flags;
            if ( ref $pat eq "REGEXP" || ref $pat eq "Regexp" ) {
                my $mod;
                ( $pat, $mod ) = regexp_pattern($pat);

                $flag |= re_flags_to_hs_flags($mod);
            }
            else {
                my $tmp = shift @{$spec};
                $flag |= $tmp if defined $tmp;
            }

            push @expressions, $pat;
            push @flags,       $flag;

            my $explicit_id = shift @{$spec};
            push @ids, defined $explicit_id ? $explicit_id : $id;

            push @ext, ( shift @{$spec} );
        }
        elsif ( ref $spec eq "HASH" ) {
            my $pat = $spec->{expr};

            my $flag = $default_flags;
            if ( ref $pat eq "REGEXP" || ref $pat eq "Regexp" ) {
                my $mod;
                ( $pat, $mod ) = regexp_pattern($pat);

                $flag |= re_flags_to_hs_flags($mod);
            }
            else {
                $flag |= $spec->{flag} if defined $spec->{flag};
            }

            push @expressions, $pat;
            push @flags,       $flag;

            push @ids, defined $spec->{id} ? $spec->{id} : $id;

            push @ext, $spec->{ext};
        }
        else {
            carp "unknown ref type ", ref $spec, $spec;
        }
    }

    my $has_ext = grep { defined } @ext;
    my $count   = scalar @expressions;

    if ($literal) {
        croak "can't use both ext and literal"
          if $has_ext;

        if ( $count == 1 ) {
            $self->{db} =
              Hyperscan::Database->compile_lit( @expressions, @flags, $mode );
        }
        else {
            $self->{db} =
              Hyperscan::Database->compile_lit_multi( \@expressions, \@flags,
                \@ids, $mode );
        }
    }
    else {
        if ($has_ext) {
            $self->{db} =
              Hyperscan::Database->compile_ext_multi( \@expressions, \@flags,
                \@ids, \@ext, $mode );
        }
        else {
            if ( $count == 1 ) {
                $self->{db} =
                  Hyperscan::Database->compile( @expressions, @flags, $mode );
            }
            else {
                $self->{db} =
                  Hyperscan::Database->compile_multi( \@expressions, \@flags,
                    \@ids, $mode );
            }
        }
    }

    $self->{scratch} = $self->{db}->alloc_scratch();

    if ( $self->{mode} eq "stream" ) {
        $self->{stream} = $self->{db}->open_stream();
    }

    return;
}

sub scan {
    my $self = shift;

    my $data = shift;

    my %args = @_;

    my $flags = defined $args{flags} ? $args{flags} : 0;

    my $max_matches = $args{max_matches};

    my $count = 0;
    my @matches;
    my $callback = sub {
        my ( $id, $from, $to, $flags ) = @_;
        push @matches, { id => $id, from => $from, to => $to, flags => $flags };
        $count++;
        return $count >= $max_matches if defined $max_matches;
        return 0;
    };

    if ( $self->{mode} eq "block" ) {
        $self->{db}->scan( $data, $flags, $self->{scratch}, $callback );
    }
    elsif ( $self->{mode} eq "stream" ) {
        $self->{stream}->scan( $data, $flags, $self->{scratch}, $callback );
    }
    elsif ( $self->{mode} eq "vectored" ) {
        $self->{db}->scan_vector( $data, $flags, $self->{scratch}, $callback );
    }
    else {
        croak "unknown mode $self->{mode}";
    }

    return @matches;
}

sub reset {
    my ( $self, $flags ) = @_;

    croak "reset only supported in stream mode"
      if $self->{mode} ne "stream";

    $flags = 0 if not defined $flags;

    my @matches;
    my $callback = sub {
        my ( $id, $from, $to, $flags ) = @_;
        push @matches, { id => $id, from => $from, to => $to, flags => $flags };
        return 0;
    };

    $self->{stream}->reset( $flags, $self->{scratch}, $callback );

    return @matches;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hyperscan::Matcher - high level matcher class

=head1 VERSION

version 0.03

=head2 CONSTRUCTORS

=head3 new( \@specs, %args )

Construct a new matcher object using the C<@specs> provided.

Accepts the following named arguments:

=over

=item default_flags

Flags that will be applied to all patterns, default: C<HS_FLAG_SOM_LEFTMOST>.

=item literal

Whether the specs provided should be compiled literally.

=item mode

The underlying hyperscan mode to use, default: C<"block">.

=back

=head4 Specs

A spec can take a few forms

=over

=item String

The string is used as the pattern, the flags are the default flags and the id
is the index in the list.

=item Regex

A perl Regex object is broken down into it's pattern and flags. The flags are
combined with the default flags and the id is the index in the list.

=item Array

The first item is shifted and uses the String or Regex behaviour above. If the
item is a string an additional item is shifted to be used as the flags. The
next elements in the array are taken to be the id and the ext hash.

=item Hash

A hash with the following keys

=over

=item expr

A String or Regex.

=item flag

Flags, ignored if a Regex is uses as the expr.

=item id

Explicit match ID.

=item ext

An ext hash.

=back

=back

=head2 METHODS

=head3 scan( $data, %args )

Scan the data for matches and return any results.

Accepts the following named arguments:

=over

=item flags

Flags to pass down into hyperscan.

=item max_matches

Limit the number of matches found while scanning.

=back

=head3 reset( $flags )

Resets the current stream and returns any remaining matches, for example
matches that contain a C<$>.

=head1 AUTHOR

Mark Sikora <marknsikora@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Mark Sikora.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
