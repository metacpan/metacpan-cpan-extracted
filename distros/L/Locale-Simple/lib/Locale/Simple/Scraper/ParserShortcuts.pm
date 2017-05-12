use strict;
use warnings;

package Locale::Simple::Scraper::ParserShortcuts;
BEGIN {
  $Locale::Simple::Scraper::ParserShortcuts::AUTHORITY = 'cpan:GETTY';
}
$Locale::Simple::Scraper::ParserShortcuts::VERSION = '0.019';
# ABSTRACT: LSS::Parser methods that are generic shortcuts to P::MGC functionality

use Moo::Role;

has debug_sub => (
    is      => 'ro',
    default => sub {
        sub { shift, warn "- " . sprintf shift() . "\n", @_ }
    }
);

sub debug { shift->debug_sub->( @_ ) }

sub collect_from {
    my ( $self, $methods ) = @_;
    return map { $self->$_ } @{$methods};
}

sub named_token {
    my ( $self, $name, $type ) = @_;
    $type ||= "constant_string";
    my $token = $self->maybe( sub { $self->$type } ) or $self->fail( "Expected $name" );
    return $token;
}

sub c_expect_escaped {
    my ( $self, $char ) = @_;
    return sub {
        $self->expect( qr/\\\Q$char\E/ );
        return $char;
    };
}

sub warn_failure {
    my ( $self, $f ) = @_;
    my ( $linenum, $col, $text ) = $self->where( $f->{pos} || $self->pos );
    my $indent = substr( $text, 0, $col );
    $_ =~ s/\t/    /g for $text, $indent;
    $indent =~ s/./-/g;     # blank out all the non-whitespace
    $text   =~ s/\%/%%/g;
    $self->debug( "$f->{message}:\n |$text\n |$indent^" );
    return;
}

sub c_any_of {
    my ( $self, @args ) = @_;
    return sub {
        $self->any_of( @args );
    };
}

sub c_expect {
    my ( $self, @args ) = @_;
    return sub {
        $self->expect( @args );
    };
}

sub c_with_ws {
    my ( $self, $code, @args ) = @_;
    return sub {
        local $self->{patterns}{ws} = qr//;
        return $self->$code( @args );
    };
}

sub with_ws {
    my ( $self, $code, @args ) = @_;
    local $self->{patterns}{ws} = qr//;
    return $self->$code( @args );
}

1;

__END__

=pod

=head1 NAME

Locale::Simple::Scraper::ParserShortcuts - LSS::Parser methods that are generic shortcuts to P::MGC functionality

=head1 VERSION

version 0.019

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by DuckDuckGo, Inc. L<http://duckduckgo.com/>, Torsten Raudssus <torsten@raudss.us>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
