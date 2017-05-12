package Javascript::Closure;
use 5.008008;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
our $VERSION = 0.07;

use constant {
    WHITESPACE_ONLY         => 'WHITESPACE_ONLY',
    SIMPLE_OPTIMIZATIONS    => 'SIMPLE_OPTIMIZATIONS',
    ADVANCED_OPTIMIZATIONS  => 'ADVANCED_OPTIMIZATIONS',
    QUIET					=> 'QUIET',
    DEFAULT					=> 'DEFAULT',
    VERBOSE					=> 'VERBOSE',
    COMPILED_CODE           => 'compiled_code',
    WARNINGS                => 'warnings',
    ERRORS                  => 'errors',
    STATISTICS              => 'statistics',
    TEXT                    => 'text',
    JSON                    => 'json',
    XML                     => 'xml',
    CLOSURE_COMPILER_SERVICE=>'http://closure-compiler.appspot.com/compile'
};

my  @compilation_level = qw(WHITESPACE_ONLY SIMPLE_OPTIMIZATIONS ADVANCED_OPTIMIZATIONS);
my  @output_info       = qw(COMPILED_CODE WARNINGS ERRORS STATISTICS);
my  @output_format     = qw(TEXT JSON XML);
my  @warning_level     = qw(QUIET DEFAULT VERBOSE);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK   = ('minify',@compilation_level,@output_info,@output_format,@warning_level);
our %EXPORT_TAGS = (CONSTANTS => [@compilation_level,@output_info,@output_format,@warning_level]);

our $TIMEOUT     = 5;

sub minify {
  my %args = @_;

  my %send                 = ();
  $send{output_info}       = _verify(\@output_info,      $args{output_info}      ,'lower') || COMPILED_CODE;
  $send{output_format}     = _verify(\@output_format,    $args{output_format}    ,'lower') || TEXT;  
  $send{compilation_level} = _verify(\@compilation_level,$args{compilation_level}        ) || WHITESPACE_ONLY; 
  $send{warning_level}     = _verify(\@warning_level    ,$args{warning_level}            ) || DEFAULT;  

  my $js                   = $args{input} || 'var test=true;//this is a test';
  #create the user agent
  my $ua   = _create_ua();
  my $source               = _cleanup_code_source($ua,$js);

  $send{js_code}  = $source->{js_code}  if(@{ $source->{js_code}  }  > 0);
  $send{code_url} = $source->{code_url} if(@{ $source->{code_url} }  > 0);

  return  _compile($ua,\%send);
}

#hacky i know
sub _verify {
  my ($vars,$value,$lower) = @_;

  return undef if(!$value);#set default value

  $value = [$value] if(ref($value) ne 'ARRAY');

  my $choice = join(',',@$vars);
  $choice    = "\L$choice" if($lower);

  foreach my $val (@$value){
  	  croak $val.' is not in:'.$choice if($val && !grep(/^$val$/i,@$vars));
	  $val = ($lower) ? "\L$val" :"\U$val";
  }
  return $value;
}

sub _create_ua {
  my $ua = LWP::UserAgent->new;
     $ua-> agent(__PACKAGE__."/".$VERSION);
     $ua-> timeout($TIMEOUT);
  return $ua;
}

sub _compile {
  my ($ua,$args)=@_;

  my $res = $ua->post(CLOSURE_COMPILER_SERVICE,$args);
  return $res->content if ($res->is_success);

  croak 'Fail to connect to '.CLOSURE_COMPILER_SERVICE.':'.$res->as_string;
}

sub _cleanup_code_source {
   my ($ua,$code_source) = @_;

   $code_source = [$code_source] if(ref($code_source) ne 'ARRAY');

   my (@str,@urls);
   foreach my $js (@$code_source) {
       if($js!~m{^http://}){
           push @str,$js; next;
       }
	   if($ua->get($js)->is_success){
		   push @urls,$js;
	   }
	   else {
		   carp 'The following url could not be fetched:'.$js;
	   }
   }
   return {
	   js_code  =>\@str,
	   code_url =>\@urls
   };
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

Javascript::Closure - compress your javascript code using Google online service of Closure Compiler 

=head1 SYNOPSIS

    #nothing is imported by default
    use Javascript::Closure qw(minify :CONSTANTS); 

    #open a file
    open (FILE,'<','jscript.js') or die $!;
    my @lines = <FILE>;
    close FILE;
	
    #compress the code. most of the time it will be all you need!
    my $compressed   = minify(input=>join('',@lines));
    
    #output the result in another file
    open FILE,'>','closure-jscript.js' or die $!;
    print FILE $compressed;
    close FILE;

    #further settings:
    my $compressed = minify(input            => [$string,'http://www.domain.com/my.js',$string2,'http://www.domain2.com/my2.js'],
                            output_format    => XML,
                            output_info      => [STATISTICS,WARNINGS,COMPILED_CODE],
                            compilation_level=> SIMPLE_OPTIMIZATIONS,
                            warning_level	 => VERBOSE
    );


=head1 DESCRIPTION

This package allows you to compress your javascript code by using the online service of Closure Compiler offered by Google
via a REST API. 

The Closure compiler offers 3 different level of compression and tools to analyze the code.

You can therefore get errors, warnings about the code and some statistics about the compression.

The Closure compiler offers also some annotations to be used in your code in order to offer optimum compression.

This can come in handy once a project is finished to merge all the files, pass it through the ADVANCED_OPTIMIZATIONS algorithm

to get the most out of it.

See L<http://closure-compiler.appspot.com/> for further information.


=head2 MOTIVATION

Needed a package to encapsulate a coherent API for a future Javascript::Minifier::Any package

and wanted a package with as few dependencies as possible.

=head2 ADVANTAGES

Gives you access to the closure compression algo with a unified API.
It also gives you access to code analyze via errors, warnings and authorizing via statistics.

=head2  SUBROUTINE


=head3 minify

=over

Takes an hash with the following parameters(parameters ended with * are optionals):

=item B<input>

Specify the javascript source to be compressed/analysed. 
It can be either an url or a scalar.

You can also use an array reference containing multiple urls or raw source code.

Example:

    use Javascript::Closure qw(minify :CONSTANTS); 
	
    my $compressed   = minify(input=>$jscode);
    my $compressed   = minify(input=>'http://www.yourdomain.com/yourscript.js');    
    my $compressed   = minify(input=>['http://www.yourdomain.com/yourscript.js','http://www.yourdomain.com/yourscript2.js',$jscode]);     


=item B<compilation_level>

Specifies the algorithm use to compress the javascript code. 
You can specify them by using one of the following constants:

 - WHITESPACE_ONLY
   remove space and comments from javascript code (default).

 - SIMPLE_OPTIMIZATIONS
   compress the code by renaming local variables.

 - ADVANCED_OPTIMIZATIONS
   compress all local variables, do some clever stripping down of the code (unused functions are removed) 
   but you need to setup external references to do it properly.



Example:

    use Javascript::Closure qw(minify :CONSTANTS); 
	
    my $compressed   = minify(input=>$jscode,compilation_level=>WHITESPACE_ONLY);

	#if you do not import the constants:
    my $compressed   = minify(input=>$jscode,compilation_level=>Javascript::Closure::WHITESPACE_ONLY);

See CONSTANTS section for further information about the algorithms.
    
=item B<output_info>

Specify the informations you will get back from the service.
it accepts either a scalar or an array reference.
You can specify them by using the following constants:

 - COMPILED_CODE 
   return only the raw compressed javascript source code (default).

 - WARNINGS
   return any warnings found by the Closure Compiler (ie,code after a return statement)

 - ERRORS
   return any errors in your javascript code found by the Closure Compiler

 - STATISTICS
   return some statistics about the compilation process (original file size, compressed file size, time,etc)

See L<http://code.google.com/intl/ja/closure/compiler/docs/api-ref.html#output_info> for further information.

Example:

    use Javascript::Closure qw(minify :CONSTANTS); 
	
	#you just want to get the code analysed before compression
    my $warnings   = minify(input=>$jscode,output_info=>WARNINGS);

	#only the errors in your code
    my $errors   = minify(input=>$jscode,output_info=>ERRORS);

	#everything was ok so you want to compressed code and some statistics about the efficiency of the compresssion
    my $errors   = minify(input=>$jscode,output_info=>[COMPILED_CODE,STATISTICS]);
     
=item B<output_format>

Specify the format of the response.
It can be one of the following constants:

 - TEXT
   return the output in raw text format with the information set with your output_info settings (default).

 - XML
   return the output in XML format with the information set with your output_info settings.

 - JSON
   return the output in JSON format with the information set with your output_info settings.

See L<http://code.google.com/intl/ja/closure/compiler/docs/api-ref.html#out> for further information.

Example:

    use Javascript::Closure qw(minify :CONSTANTS); 
	
	#the default
    my $warnings   = minify(input=>$jscode,output_format=>TEXT);

	#get back the response as XML
    my $errors   = minify(input=>$jscode,output_format=>XML);

	#get back the response as JSON
    my $compress   = minify(input=>$jscode,output_format=>JSON);

Specifying the format can be useful if you want not only the compiled code but warnings,errors or statistics.
Though minify only returns the compressed version of the javascript code as a scalar,you can easily json-ify it 
to retrieve the information (you could do so with a corresponding XML module):

Example:

    use Javascript::Closure qw(minify :CONSTANTS); 
	use JSON;
	
	#the default
    my $output     = minify(input=>$jscode,output_format=>JSON,output_info=>[COMPILED_CODE,STATISTICS]);

	#change the raw string into perl structure
	my $response   = from_json($output);

	my $statistics = $response->{statistics};
	say $statistics->{originalSize};
	say $statistics->{compressedSize};


Javascript::Closure does not offer shortcuts access to errors,warnings or statistics for now.
Might add a Javascript::Closure::Response::JSON to make thing even sweeter but access through an hash is certainly faster
and the overhead of function call does not seem necessary...

=item B<warning_level>

Specifies the amount of information you will get when you set the output_info to WARNINGS. 
You can specify them by using one of the following constants:

 - DEFAULT

   default

 - QUIET

 - VERBOSE


See L<http://code.google.com/intl/ja/closure/compiler/docs/api-ref.html#warn> for further information.

Example:

    use Javascript::Closure qw(minify :CONSTANTS); 
	
    my $compressed   = minify(input            => $jscode,
                              compilation_level=> WHITESPACE_ONLY,
                              output_info      => [COMPILE_CODE,WARNINGS],
                              warning_level    => VERBOSE
    );


=back

=head3  CONSTANTS

Each optional parameter to minify can be specified via constants.
If you do not import the :CONSTANTS, you will have to write Javascript::Closure::NAME_OF_THE_CONSTANT;

=head1 PACKAGE PROPERTY

=head2 TIMEOUT

=over

Set by default to 5s. You can modify it if you need to:

    $Javascript::Closure::Timeout=15;

=back


=head2 DIAGNOSTICS

=head3 croak

=over

=item C<< Fail to connect to http://closure-compiler.appspot.com/compile: ... >>

The module could not connect and successfully compress your javascript. 
See the detail error to get a hint.

=item C<< ... is not in:...(list of possible value) >>

One of the optional parameter received does not contain an authorized predefined value. 

=back

=head3 carp

=over

=item C<< The following url could not be fetched::...(url that failed) >>

The module could not connect to the url. 
See the detail error to get a hint.

=back

=head2 TODO

=over

=item B<optional parameters>

none of the following optional parameters are supported:

 - use_closure_library
 - formatting
 - output_file_name
 - exclude_default_externs
 - externs_url
 - js_externs

=item B<copyrights information>

If you use the Closure Compiler annotations, you can keep the copyright notice within the comments.
If you do not use them though, this package will still offer you a way to add copyright notice after the compression is done.


=back


=head1  SEE ALSO

=item B<other related modules>

L<WebService::Google::Closure>

L<JavaScript::Minifier>

L<JavaScript::Packer>

L<JavaScript::Minifier::XS>

L<http://closure-compiler.appspot.com/>

=back

=head1  CONFIGURATION AND ENVIRONMENT

none


=head1  DEPENDENCIES

L<LWP::UserAgent>

=head1  INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
