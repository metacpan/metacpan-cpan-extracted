use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::Test;

our $VERSION = '1.710';

use Log::Any::Adapter::Util qw/dump_one_line/;
use Test::Builder;

use Log::Any::Adapter::Base;
our @ISA = qw/Log::Any::Adapter::Base/;

my $tb = Test::Builder->new();
my @msgs;

# Ignore arguments for the original adapter if we're overriding, but recover
# category from argument list; this depends on category => $category being put
# at the end of the list in Log::Any::Manager. If not overriding, allow
# arguments as usual.

sub new {
    my $class = shift;
    if ( defined $Log::Any::OverrideDefaultAdapterClass
        && $Log::Any::OverrideDefaultAdapterClass eq __PACKAGE__ )
    {
        my $category = pop @_;
        return $class->SUPER::new( category => $category );
    }
    else {
        return $class->SUPER::new(@_);
    }
}

# All detection methods return true
#
foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    *{$method} = sub { 1 };
}

# All logging methods push onto msgs array
#
foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    *{$method} = sub {
        my ( $self, $msg ) = @_;
        push(
            @msgs,
            {
                message  => $msg,
                level    => $method,
                category => $self->{category}
            }
        );
    };
}

# Testing methods below
#

sub msgs {
    my $self = shift;

    return \@msgs;
}

sub clear {
    my ($self) = @_;

    @msgs = ();
}

sub contains_ok {
    my ( $self, $regex, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test_name ||= "log contains '$regex'";
    my $found =
      _first_index( sub { $_->{message} =~ /$regex/ }, @{ $self->msgs } );
    if ( $found != -1 ) {
        splice( @{ $self->msgs }, $found, 1 );
        $tb->ok( 1, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        $tb->diag( "could not find message matching $regex" );
        _diag_msgs();
    }
}

sub category_contains_ok {
    my ( $self, $category, $regex, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test_name ||= "log for $category contains '$regex'";
    my $found =
      _first_index(
        sub { $_->{category} eq $category && $_->{message} =~ /$regex/ },
        @{ $self->msgs } );
    if ( $found != -1 ) {
        splice( @{ $self->msgs }, $found, 1 );
        $tb->ok( 1, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        $tb->diag( "could not find $category message matching $regex" );
        _diag_msgs();
    }
}

sub does_not_contain_ok {
    my ( $self, $regex, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test_name ||= "log does not contain '$regex'";
    my $found =
      _first_index( sub { $_->{message} =~ /$regex/ }, @{ $self->msgs } );
    if ( $found != -1 ) {
        $tb->ok( 0, $test_name );
        $tb->diag( "found message matching $regex: " . $self->msgs->[$found]->{message} );
    }
    else {
        $tb->ok( 1, $test_name );
    }
}

sub category_does_not_contain_ok {
    my ( $self, $category, $regex, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test_name ||= "log for $category contains '$regex'";
    my $found =
      _first_index(
        sub { $_->{category} eq $category && $_->{message} =~ /$regex/ },
        @{ $self->msgs } );
    if ( $found != -1 ) {
        $tb->ok( 0, $test_name );
        $tb->diag( "found $category message matching $regex: "
              . $self->msgs->[$found] );
    }
    else {
        $tb->ok( 1, $test_name );
    }
}

sub empty_ok {
    my ( $self, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test_name ||= "log is empty";
    if ( !@{ $self->msgs } ) {
        $tb->ok( 1, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        $tb->diag( "log is not empty" );
        _diag_msgs();
        $self->clear();
    }
}

sub contains_only_ok {
    my ( $self, $regex, $test_name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test_name ||= "log contains only '$regex'";
    my $count = scalar( @{ $self->msgs } );
    if ( $count == 1 ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->contains_ok( $regex, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        _diag_msgs();
    }
}

sub _diag_msgs {
    my $count = @msgs;
    if ( ! $count ) {
        $tb->diag("log contains no messages");
    }
    else {
        $tb->diag("log contains $count message" . ( $count > 1 ? "s:" : ":"));
        $tb->diag(dump_one_line($_)) for @msgs;
    }
}

sub _first_index {
    my $f = shift;
    for my $i ( 0 .. $#_ ) {
        local *_ = \$_[$i];
        return $i if $f->();
    }
    return -1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Test

=head1 VERSION

version 1.710

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
