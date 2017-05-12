package Finance::Optical::StrongBuy;

use strict;
use warnings;
use Carp;
use GD;
use GD::Image;
use Data::Dumper;
use WWW::Mechanize;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Finance::Optical::StrongBuy ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
        
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
callCheck new recommended
);

our $VERSION = '0.09';

our $img = "";

our $result = {};
 

sub recommended {
    my $class = shift;

    $class->new("/tmp");
}

sub new {
    my $class = shift;
    my $this  = bless {
    }, $class;

    my $dir = shift;
    if( defined $dir ) {
        $this->set_path( $dir );
        $this->{result}=$result;
    }else{
        croak "need a working directory";
    }

    return $this;
}

sub set_path {
    my $this = shift;
    my $arg  = shift;
            
    croak "need a working directory" if !defined($arg);


    $this->{dir} = $arg;

}




sub get_source_image
{
my($this)= shift;
my ($json_url) = @_;
my $EXIT_CODE = 1;

my $browser = WWW::Mechanize->new(
        stack_depth     => 0,
        timeout         => 3,
        autocheck       => 0,
);
$browser->get( $json_url );

if ( $browser->success( ) ) {
#        print "OK:",$browser->response->status_line(),"\n";
        $EXIT_CODE=0;
}
else {
     #   print "Fail:",$browser->response->status_line(),"\n";
        $EXIT_CODE=1;
}


sub writeImg  {

my($this)= shift;


my ($raw,$file) = @_;

    if($raw !~/404/){
    open(OUT, '>', $file);
    print OUT $raw;
    close(OUT);
    }
}


my $content = "";


   $content = $browser->content() unless($EXIT_CODE);

return $content;

}


sub callCheck  {

    my($this)= shift;

    my($symbol)= shift;

        my $raw = $this->get_source_image(sprintf("http://content.nasdaq.com/ibes/%s_Smallcon.jpg",$symbol));

        my $l = length $raw;

        return if($raw =~ m/404|Fail:400 Bad Request/ ||  $l == 0);
        
        $this->writeImg($raw,sprintf("%s/%s_Smallcon.jpg",$this->{dir},$symbol));
          croak("shit image") unless (defined $raw);
            {
                $img = GD::Image->newFromJpeg(sprintf("%s/%s_Smallcon.jpg",$this->{dir},$symbol));
                my $myImage = new GD::Image(10,1);

                # copy a pixel region from $srcImage to
                # the rectangle to look for black pixel which marks match 
                # have reduced it strikt right have in strong buy
                
                next if(!$img);
                #
                $myImage->copy($img,0,0,105,11,10,10);

                binmode STDOUT;
                
                open (PNG, sprintf(">%s/%s.png",$this->{dir},$symbol));
                print PNG $myImage->png;
                close (PNG); 

                my $sig = $myImage->colorsTotal>=18?'strong buy':undef;

                next unless ($sig);
                
                $this->{result}->{$symbol} =$sig;
            } 
        
  }
  
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::Optical::StrongBuy - analyses a image [strong-sell,sell,hold,buy,strong-buy] for given stock, released by Institutional Brokers Estimate System

=head1 SYNOPSIS


    use Finance::Optical::StrongBuy;
    use Data::Dumper;

    my $new = Finance::Optical::StrongBuy->new("/tmp");

    foreach my $symbol (qw/C BAC WFC WM F GE AAPL GOOG/) {
     $new->callCheck($symbol);
    }

    print Dumper [$new];

=head1 DESCRIPTION

analyses a image [strong-sell,sell,hold,buy,strong-buy] for given stock, released by Institutional Brokers Estimate System

http://content.nasdaq.com/ibes/GOOG_Smallcon.jpg

=head2 EXPORT

None by default.

=head1 SEE ALSO

Finance::Google::Sector::Mean
Finance::NASDAQ::Markets

=head1 AUTHOR

Hagen Geissler

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Hagen Geissler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

