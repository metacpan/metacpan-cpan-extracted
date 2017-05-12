#$Id: Wortschatz.pm 1151 2008-10-05 20:57:26Z schroeer $

package Lingua::DE::Wortschatz;

use strict;
use SOAP::Lite;# +trace=>'all';
use HTML::Entities;
use Text::Autoformat;
use Exporter 'import';
use Data::Dumper;
$Data::Dumper::Indent=1;

our @EXPORT_OK = qw(use_service help);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
 
our $VERSION = "1.27";

my $BASE_URL = 'http://anonymous:anonymous@pcai055.informatik.uni-leipzig.de:8100/axis/services/';
my $LIMIT    = 10;
my $MINSIG   = 1;

#description of available services and necessary corpus, in and out parameters
my %services=( # service_name => [ 'corpus', [ 'inparam<=default>', .. ], [ 'outparam', .. ] )
    ServiceOverview => [ 'webservice', ['Name='], ['Name','Id','Status','Description','AuthorizationLevel','InputFields'] ],
    Cooccurrences   => [ 'de', ['Wort',"Mindestsignifikanz=$MINSIG","Limit=$LIMIT"], ['Wort','Kookkurrenz','Signifikanz'] ],
    Baseform        => [ 'de', ['Wort'], ['Grundform','Wortart'] ],
    Sentences       => [ 'de', ['Wort',"Limit=$LIMIT"], ['Satz'] ],
    RightNeighbours => [ 'de', ['Wort',"Limit=$LIMIT"], ['Wort','Nachbar','Signifikanz'] ],
    LeftNeighbours  => [ 'de', ['Wort',"Limit=$LIMIT"], ['Nachbar','Wort','Signifikanz'] ],
    Frequencies     => [ 'de', ['Wort'], ['Anzahl','Frequenzklasse'] ],
    Synonyms        => [ 'de', ['Wort',"Limit=$LIMIT"], ['Synonym'] ],
    Thesaurus       => [ 'de', ['Wort',"Limit=$LIMIT"], ['Synonym'] ],
    Wordforms       => [ 'de', ['Word',"Limit=$LIMIT"], ['Form'] ], #find the trap that wortschatz.u-l guys have hidden here
    Similarity      => [ 'de', ['Wort',"Limit=$LIMIT"], ['Wort','Verwandter','Signifikanz'] ],
    LeftCollocationFinder
                    => [ 'de', ['Wort','Wortart',"Limit=$LIMIT"], ['Kollokation','Wortart','Wort'] ],
    RightCollocationFinder
                    => [ 'de', ['Wort','Wortart',"Limit=$LIMIT"], ['Wort','Kollokation','Wortart'] ],
    Sachgebiet      => [ 'de', ['Wort'], ['Sachgebiet'] ],
    Kreuzwortraetsel
                    => [ 'de', ['Wort','Wortlaenge',"Limit=$LIMIT"], ['Wort'] ],
);

sub use_service {
    #returns a Lingua::DE::Wortschatz::Result object

    #get input parameters and set defaults or return undef if service unknown or insufficent parameters
    my $service=parse_servicename(shift) || return undef;
    my %params;
    for (@{$services{$service}->[1]}) {
        if (/([^=]+)=(.*)/) { $params{$1}=shift || $2}
        else                { $params{$_}=shift || return undef }
    }
    my $corpus=$services{$service}->[0];
    my @resultnames=@{$services{$service}->[2]};

    # perform the soap query
    my $soap = SOAP::Lite->proxy($BASE_URL.$service); 
    my $result=$soap->execute(make_params($corpus,\%params));
    #print Dumper($result);
    #print $soap->execute(make_params($corpus,\%params))->{_context}->{_transport}->{_proxy}->{_http_response}->{_content};
    die "SOAP has returned an error (".$result->faultcode."):\n".$result->faultstring if ($result->fault);
        
    # bring results into shape
    # wortschatz has two different kind of return types; kind of scalar and list
    my @res=$result->valueof('//result/'.((@resultnames > 1) ? '*' : 'dataVectors').'/*');
    my $resobj=Lingua::DE::Wortschatz::Result->new($service,@resultnames);
    $resobj->add(splice @res,0,@resultnames) while (@res);
    return $resobj;
}

sub help {
    my $cmd=shift || 'list';
    $cmd = parse_servicename($cmd) || 'list' unless ($cmd =~ /(list)|(full)/);
    my @so=use_service('ServiceOverview')->hashrefs();
    my $help=($cmd =~ /(list)|(full)/) ? "Available services:\n" : "";
    for my $so (@so) {
        my $sn=$so->{Name};
        if ($services{$sn} && (($sn =~ /^$cmd/) || ($cmd =~ /(list)|(full)/))) {
            $help.=sprintf "* %s %s %s %s\n",$sn,@{$services{$sn}->[1]},"","","";
            unless ($cmd eq 'list') {
                my $t="\n  ".decode_entities($so->{Description})."\n\n";
                $help.=autoformat($t,{all=>1})."\n";
            }
        }
    }
    return $help;
}

sub make_params {
    # create the soap request parameters by hand
    # not the idea of soap, but everything else failed (see manpage)
    my ($corpus,$params)=@_;
    my $ns='http://datatypes.webservice.wortschatz.uni-leipzig.de';
    my $xml="<objRequestParameters><corpus>$corpus</corpus><parameters>";
    my $num=1;
    for (keys %$params) {
        $xml.=q (<dataVectors>).
              qq(<ns$num:dataRow xmlns:ns$num="$ns">$_</ns$num:dataRow>).
              qq(<ns$num:dataRow xmlns:ns$num="$ns">$$params{$_}</ns$num:dataRow>).
              q (</dataVectors>);
        $num++;
    }
    $xml.='</parameters></objRequestParameters>';
    SOAP::Data->type(xml=>$xml);
}

sub parse_servicename {
    my ($service)=grep(/^$_[0]/,keys %services);
    return $service;
}

package Lingua::DE::Wortschatz::Result;
use strict;

our $VERSION = $Lingua::DE::Wortschatz::VERSION;

sub new {
    my ($proto,$service,@names) = @_;
    my $class = ref($proto) || $proto;
    return bless { service => $service, names => \@names, data => [] }, $class;
}

sub add {
    my ($self,@values)=@_;
    push(@{$self->{data}},\@values);
}

sub dump {
    my $self=shift;
    print "Service ",$self->service,"\n\n";
    my @lengths;
    for my $row ($self->data,$self->{names}) {
        for (0..$#$row) {
            my $l=length($row->[$_]);
            $lengths[$_]=$l unless ($lengths[$_] && ($lengths[$_] > $l));
        }
    }
    my $form=(join " ",map {'%-'.$_.'s'} @lengths)."\n";
    printf $form,$self->names;
    printf $form, map {"-"x$_} @lengths;
    printf $form,@$_ for ($self->data);
}

sub service { shift->{service} }
    
sub names { @{shift->{names}} }
    
sub data { @{shift->{data}} }
    
sub hashrefs {
    my $self=shift;
    my @res=();
    for (@{$self->{data}}) {
        my %hash;
        @hash{@{$self->{names}}}=@$_;
        push(@res,\%hash);
    }
    return @res;
}

1;

__END__

=head1 NAME

Lingua::DE::Wortschatz - wortschatz.uni-leipzig.de webservice client

=head1 SYNOPSIS

    use Lingua::DE::Wortschatz;
    # use Lingua::DE::Wortschatz ':all'; # import all functions
    
    my $result=Lingua::DE::Wortschatz::use_service('T','toll');
    # my $result=use_service('T','toll'); # with imported functions
    
    $result->dump;
    
    @lines=$result->hashrefs();
    for (@lines) {
        print $_->{Synonym},"\n";
    }

    print Lingua::DE::Wortschatz::help('T');
    print Lingua::DE::Wortschatz::help('full');
    
    $result->dump;

=head1 DESCRIPTION

This is a full featured client for the webservices
at L<http://wortschatz.uni-leipzig.de>.
The script C<wsws.pl> is a command line client that
uses this lib. It is contained in this distribution.

The webservices at L<http://wortschatz.uni-leipzig.de> provide
access to a database of the german word pool. Available
services include tools to reduce words to base form, find synonyms,
significant neighbours, example sentences and more. All public
services at L<http://wortschatz.uni-leipzig.de> are available
through this client. See the detailed list below.

The author of this module has nothing to do with the University of Leipzig or the Wortschatz
project.

This module allows to perform automated queries with perl scripts.
It can be used from the command line, too. There is no GUI.

This program will run on Windows if Perl is installed.

=head1 FUNCTIONS

The following functions can be exported or used via the full name.

=head2 use_service($name,@args)

Uses the webservice named C<$name> with arguments C<@args>.
Returns a L<result object|THE RESULT OBJECT> that is described below. Returns C<undef> if an insufficient number of arguments for the desired
service is supplied.

All public services at L<http://wortschatz.uni-leipzig.de> are
available. Below is a list of service names and their parameters.
Any parameter with = is optional and defaults to the given value.
Service names can be abbreviated to the shortest unique form.

  * ServiceOverview Name=
  * Cooccurrences Wort Mindestsignifikanz=1 Limit=10
  * Baseform Wort
  * Sentences Wort Limit=10
  * RightNeighbours Wort Limit=10
  * LeftNeighbours Wort Limit=10
  * Frequencies Wort Limit=10
  * Synonyms Wort Limit=10
  * Thesaurus Wort Limit=10
  * Wordforms Word Limit=10
  * Similarity Wort Limit=10
  * LeftCollocationFinder Wort Wortart Limit=10
  * RightCollocationFinder Wort Wortart Limit=10
  * Sachgebiet Wort  
  * Kreuzwortraetsel Wort Wortlaenge Limit=10

A full list of available services, their parameters
and additional information on what each service does
can be obtained with the help function.

For the Kreuzwortraetsel service, use % as a placeholder in parameter Wort.

=head2 help(?$service)

Returns a string containing information about the service named C<$service>.
If no service name is given,
a short list of all available services is returned. If
C<$service eq 'full'>, a more detailed list is created.

=head1 THE RESULT OBJECT

The C<use_service> function returns a result object of class
C<Lingua::DE::Wortschatz::Result> that holds the results.

This object offers methods to conveniently access the data.

=head2 dump()

 $result->dump();

Pretty prints the data to STDOUT.

=head2 service()

 $service_name=$result->service();

Returns the name of the service that was used to obtain the data.

=head2 names()

 @column_headers=$result->names();

Returns a list of the names of the data columns.

=head2 data()

 @rows=$result->data();

Returns a list of datasets. Each dataset is a reference to a list of values.

=head2 hashrefs()

 @lines=$result->hashrefs();

Returns a list of datasets. Each dataset is a references to
a hash. The hashkeys are the names of the return values and
the values are the data.

=head1 CAVEATS/BUGS

I wrote this to understand SOAP better. It took me way too long, due to
the lack of documentation.

I couldn't figure out how to make SOAP::Lite and SOAP::Data create the
request parameters in the correct way. It appears to me that this would
require me to create custom as_Datatype functions for all the used types.

I could neither make it work using the WSDL file. I think with the data
format that wortschatz.u-l requires, WSDL is pretty useless.

So I decided to use a straightforward approach and create the XML request
parameters myself. This is probably not the idea of that whole SOAP thing,
but it is short and it works. It's a hack.

=head1 SEE ALSO

=over

=item L<http://wortschatz.uni-leipzig.de>

=item L<SOAP::Lite>

=back

=head1 AUTHOR/COPYRIGHT

This is C<$Id: Wortschatz.pm 1151 2008-10-05 20:57:26Z schroeer $>.

Copyright 2005 - 2008 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut  
