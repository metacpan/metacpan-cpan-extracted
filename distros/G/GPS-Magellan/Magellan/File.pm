
package GPS::Magellan::File;

use strict;
use warnings;
use Data::Dumper;
use vars qw($AUTOLOAD);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args = @_;

    
    my $self = bless { 
        coords => $args{coords} || [],
    }, $class;

    $self->_init();

    return $self;
}

sub _init {
    my $self = shift;

}

sub read {
    my $self = shift;
    my $file = shift;

    my @raw = ();

    if($file){
        open(INPUT, $file) or die sprintf("%s::read(): cannot open %s\n", ref($self), $file);
        @raw = <INPUT>;
        close(INPUT);
    } else {
        @raw = <STDIN>;
    }

    $self->decode(\@raw);
}

sub as_string {
    shift->encode();
}


sub write {
    my $self = shift;
    my $file = shift;

    if($file){
        open(OUTPUT, ">$file") or die sprintf("%s::write(): cannot open %s\n", ref($self), $file);
        print OUTPUT $self->encode();
        close(OUTPUT);
    } else {
        print $self->encode();
    }
    return;
}


# Interface to be implemented by subclasses representing various file formats

sub name { 'PLACEHOLDER' }

sub encode { '' }

sub decode { [] }

sub can_read { 0 }


# Accessors
sub _get {
    my $self = shift;
    my $attr = shift;
    return $self->{$attr};
}

sub _set {
    my $self = shift;
    my $attr = shift;
    my $value = shift || '';

    return unless $attr;

    $self->{$attr} = $value;
    return $self->_get($attr);
}

sub _debug_autoload {
    my $self = shift;
    $self->_set('_debug_autoload', shift) if @_;
    $self->_get('_debug_autoload');
}

    
sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;

    $attr =~ s/.*:://;

    return if $attr =~ /^_/;

    warn "AUTOLOAD: $attr\n" if $self->_debug_autoload;

    if(@_){
        $self->_set($attr, shift);
    }
    return $self->_get($attr);
}

sub DESTROY {

}

package GPS::Magellan::File::Way_Txt;

use strict;

use base qw/GPS::Magellan::File/;

sub name { 'GpsDrive way.txt' }

# FILE FORMAT:
# EEMSSTRA               5220.484000  454.569000 0000016M
# WPT002                 5220.879000  454.287000 0000000M

sub encode {
    my $self = shift;

    my @output = ();

    foreach my $c (@{$self->coords}){
        push @output, sprintf("%-22s %04.6f  %04.6f %07d%s\n", $c->name, $c->longitude, $c->latitude, $c->altitude, $c->unknown);
    }
    @output;
}

sub decode {
    my $self = shift;
}


1;

__END__

=head1 NAME

GPS::Magellan::Message - Module encapsulating Magellan (NMEA) messages

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

This class is being used internally by the L<GPS::Magellan> class.

=head1 METHODS

=over 4

=cut

=item new ( )


=cut


=back 4

=head1 PREREQUISITES

L<>

=head1 AUTHOR

Peter Banik E<lt>peter@geospaces.netE<gt>

=head1 SEE ALSO

L<GPS::Magellan>

=head1 VERSION

$Id: File.pm,v 1.1.1.1 2004/02/29 21:45:16 peter Exp $

=head1 BUGS

Please report bugs to the author.

=head1 COPYRIGHT

Copyright (c) 1993 - 2003 

=cut



