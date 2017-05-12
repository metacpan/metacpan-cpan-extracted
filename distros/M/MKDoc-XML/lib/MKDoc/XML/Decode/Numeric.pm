package MKDoc::XML::Decode::Numeric;
use warnings;
use strict;

sub process
{
    (@_ == 2) or warn "MKDoc::XML::Encode::process() should be called with two arguments";
    
    my $class = shift;
    
    my $stuff = shift;
    $stuff =~ s/^#// or return;
    
    # if hex, convert to hex
    $stuff =~ s/^\[xX]([0-9a-fA-F])+$/hex($1)/e;
    
    return unless ($stuff =~ /^\d+$/);
    return chr ($stuff);
}

1;

__END__
