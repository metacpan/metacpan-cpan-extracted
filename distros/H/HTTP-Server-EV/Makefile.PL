use 5.008; #Unicode
use ExtUtils::MakeMaker;
require EV::MakeMaker; #fail earlier in case it's not present

my $req =  { 
	'Time::HiRes'  => 0,
	'File::Copy'   => 0,
	'File::Util'   => 0,
	'EV'		   => 0,
	'Guard'		   => 0,
	'Scalar::Util' => 0,
	'List::Util::XS' => 0, #ensures 'weaken'
};

$| = 1;


unless (eval { require IO::AIO }){
	my $answ = prompt("- Install IO::AIO for asynchronous disk IO?",'y');

	unless( $answ =~ m/n/i ){
		$req->{'IO::AIO'} = 0;
		$req->{'AnyEvent::AIO'} = 0;
	}
}else {
	# $req->{'AnyEvent::AIO'} = 0;
}

my $DEFINE = '';
if (prompt ("Config buffer sizes (y/n)?", "n") =~ /[yY]/) {
   

print <<EOF;


	MAX_DATA
	Maximal number of multipart form fields. 
	
EOF

$DEFINE .= " -DMAX_DATA=" . int(prompt ("Number form fields?", "1024"));

print <<EOF;


	MAX_URLENCODED_BODY
	Maximal size of urlencoded form body in bytes. 
	
	Number of fields parsed from urlencoded forms can be changed in runtime by setting $HTTP::Server::EV::CGI::MAX_URLENCODED_FIELDS (default 1024). 
	Don't set large value if you don't want to become vulnerable to DoS by sending lot ( >10k ) of small form fields like all apps using CGI.pm
	
EOF

$DEFINE .= " -DMAX_URLENCODED_BODY=" . int(prompt ("Urlencoded body size?", "102400"));
  
 
print <<EOF;


	BODY_CHUNK_BUFSIZ
	Multipart form field value size limited by one chunk size.
	Max memory usage by object with post data = MAX_DATA * BODY_CHUNK_BUFSIZ
	
	This limit is not applied to files - when received file data size reaches BODY_CHUNK_BUFSIZ it flushed to disc. 
	
EOF

$DEFINE .= " -DBODY_CHUNK_BUFSIZ=" . int(prompt ("Multipart form field value size?", "51200"));
 

print <<EOF;


	SOCKREAD_BUFSIZ
	Socket read buffer size
	
EOF

$DEFINE .= " -DSOCKREAD_BUFSIZ=" . int(prompt ("Socket read buffer size?", "8096"));
 
}





my %options = (
  'TYPEMAPS' => [],
  'NAME' => 'HTTP::Server::EV',
  'VERSION' => '0.69',
  'OPTIMIZE' => ' -O2',
  'PREREQ_PM' => $req,
  'BUILD_REQUIRES' => { # for tests
    'AnyEvent::HTTP' => 0,
    'HTTP::Request::Common' => 0,
  },
  
  'CONFIGURE_REQUIRES' => {
	'EV' => 0
  },
  
  'TEST_REQUIRES' => {
	'Coro' => 0
  },
  
  'DEFINE'    => "$DEFINE",
  
  'CONFIGURE' => sub {
	return {EV::MakeMaker::ev_args(my %tmp)};
  },
  
	MIN_PERL_VERSION => '5.008',
	LICENSE => 'perl',
);
WriteMakefile1(%options);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
	my %params=@_;
	my $eumm_version=$ExtUtils::MakeMaker::VERSION;
	$eumm_version=eval $eumm_version;
	die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
	die "License not specified" if not exists $params{LICENSE};
	if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
		$params{META_ADD}->{author}=$params{AUTHOR};
		$params{AUTHOR}=join(', ',@{$params{AUTHOR}});
	}
	if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
		#EUMM 6.5502 has problems with BUILD_REQUIRES
		$params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
		delete $params{BUILD_REQUIRES};
	}
	delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
	delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
	delete $params{META_MERGE} if $eumm_version < 6.46;
	delete $params{META_ADD} if $eumm_version < 6.46;
	delete $params{LICENSE} if $eumm_version < 6.31;
	delete $params{AUTHOR} if $] < 5.005;
	delete $params{ABSTRACT_FROM} if $] < 5.005;
	delete $params{BINARY_LOCATION} if $] < 5.005;

	WriteMakefile(%params);
}

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
