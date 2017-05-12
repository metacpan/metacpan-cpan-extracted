package Lemonldap::Federation::SplitURI ;
use URI;
sub new {
my $class =shift;
my %args = @_;
my $self;
$self=\%args;
my $_uri = URI->new($self->{uri} );
$self->{scheme} = $_uri->scheme;
$self->{path} = $_uri->path;
$self->{port} = $_uri->port;
$self->{host} = $_uri->host;
bless $self,$class;
$self->splitPathURI($self);
return $self;
}



sub  splitPathURI {
my $self= shift;

my $string_of_path = $self->{path};

my @paths;
my $may_rep;
$may_page= 1 if $string_of_path !~ /\/$/ ;
my @tmp_paths = split /\// , $string_of_path ;
shift @tmp_paths ;# the first it is root directory
 if (($tmp_paths[-1]=~/\./) and ($may_page))  {   
          pop @tmp_paths ;
        }
   elsif ($may_page)  {  # must be tested ahead 
 	  pop @tmp_paths;      
 }


for my $a_path (@tmp_paths)  {
 push @paths , $a_path ;
	}

$self->{ref_paths} = \@paths ;
return 1;

}

sub get_host 
{
my $self = shift;
return $self->{host};
}
sub get_port 
{
my $self = shift;
return $self->{port};
}
sub get_scheme 
{
my $self = shift;
return $self->{scheme};
}
sub get_path 
{
my $self = shift;
return $self->{path};
}

sub get_ref_array_of_path 
{
my $self = shift;
if ($self->{ref_paths}) {  
           return  $self->{ref_paths} }
    else { return 0 ;
  } 
}

1;

