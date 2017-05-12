BEGIN {
	require 5.008003; # substr fixes
}
use ExtUtils::MakeMaker;

# This little piece of code is to solve (at least for this module) the oft-
# repeated problem of upgrades breaking code that relies on it. Releasing
# working versions of the other code is not a complete solution; the user
# has to be told as well.
# Unfortunately, previous versions of the JS plugin wouldn’t compile with-
# out WWW::Scripter loaded already. So this is a mess.
%broken_deps = (
 WWW'Scripter                   => { breaks => 0.016, use => 0.017 },
 WWW'Scripter'Plugin'JavaScript => { breaks => 0.002, use => 0.003 }
);
while(my($mod,$vers) = each %broken_deps) {
 if(eval{require WWW'Scripter}
    and eval"require $mod" and !eval{VERSION $mod $$vers{use}}) {
  push @broken_deps, $mod;
 }
}

if(@broken_deps == 1) {
  my $mod = shift @broken_deps;
  my $vers = $broken_deps{$mod};
  $message = "WARNING: This distribution breaks compatibility with"
           ." $mod $$vers{breaks} and earlier. Please consider upgrading"
           ." to version $$vers{use}.";
  print "\n";
  write;
  print "\n";
}
elsif(@broken_deps) {
 print "
WARNING: This distribution breaks compatibility with the follow-
ing modules:
",
  map "  $_ $broken_deps{$_}{breaks} and earlier - use $broken_deps{$_}{use}\n",
     @broken_deps;
 print "\n";
}

format STDOUT =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
$message
.

my %prq = (
         Carp                      => 0,
         constant                  => 1.03, # multiple at once
        'CSS::DOM'                 => 0.06, # compute_style
        'CSS::DOM::Style'          => 0.05, # modification_handler
                                            # and ::Style::parse’s
        'CSS::DOM::StyleSheetList' => 0,    # stringification
         Date'Format               => 0,
         Exporter                  => 5.57, # for use Exporter 'import'
	'HTML::Tagset'             => 0,
	'HTML::Encoding'           => 0,
         HTML::Parser              => 3,
         HTTP::Message             => eval('require HTTP::Message;
                                            VERSION HTTP::Message') == 5.81
                                            ? 5.811 : 0,
         HTTP::Request             => 0,
         HTTP::Request::Common     => 0,
         HTTP'Headers              => 1.59, # comes with LWP 5.79; for the
        'HTTP::Headers::Util'      => 0,    # header_field_names method
         overload                  => 0,
        'Scalar::Util'             => 1.09, # refaddr
         strict                    => 0,
         eval { require Hash::Util::FieldHash } ? () : (
          Tie'RefHash'Weak         =>  .08, # fieldhash
         ),
         URI                       => 0,
         warnings                  => 0,
# used only in the tests:
         CSS'DOM                   => 0.07, # !important ua rules
         HTTP'Response             => 0,
         Scalar::Util              => 1.14, # refaddr with ties
        'Test::More'               => 0,
	 utf8                      => 0,
);
$prq{HTTP'Message} = 1.34 unless $prq{HTTP'Message}; # array ref headers

WriteMakefile(
    NAME                => 'HTML::DOM',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/HTML/DOM.pm',
    ABSTRACT_FROM       => 'lib/HTML/DOM.pm',
    PL_FILES            => {},
    PREREQ_PM     => \%prq,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'HTML-DOM-*' },
);
                     
