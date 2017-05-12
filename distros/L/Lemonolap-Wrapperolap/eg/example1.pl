use Lemonolap::Wrapperolap;
my $wrapper = Lemonolap::Wrapperolap->new (config => "myxml.xml" );
foreach ('format','filter')  {
$wrapper->set_phase($_);
my $file = $wrapper->get_file_in;
my $handler= $wrapper->get_handler;
my $sortie =$wrapper->get_file_out;
eval "use $handler;";
my $hook= $handler->new();
$hook->set_output($sortie);
$hook->apply(infile =>$file,
                outfile =>$sortie,
                header =>'1' ) ;
}




