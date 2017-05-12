package Devel::Memalyzer::Base;
use strict;
use warnings;

sub gen_accessors {
    my $class = shift;
    for my $accessor ( @_ ) {
        my $sub = sub {
            my $self = shift;
            ($self->{ $accessor }) = @_ if @_;
            return $self->{ $accessor };
        };
        no strict 'refs';
        *{ $class . '::' . $accessor } = $sub;
    }
}

sub new {
    my $class = shift;
    my %proto = @_;
    return bless( \%proto, $class );
}

1;

__END__

=head1 NAME

Devel::Memalyzer::Base - Base class for Devel::Memalyzer objects.

=head1 DESCRIPTION

Provides new() and a simple accessor generator.

=head1 SYNOPSYS

    use base 'Devel::Memalyzer::Base';

    __PACKAGE__->gen_accessors qw/ a b c /;

    my $instance = __PACKAGE__->new( a => 1, b => 2, c => 3 );

    $instance->a;       #Get
    $instance->a( 55 ); #Set

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

