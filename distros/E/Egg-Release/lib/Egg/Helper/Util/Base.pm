package Egg::Helper::Util::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Getopt::Easy;
use File::Temp qw/ tempdir /;
use UNIVERSAL::require;
use Egg::Exception;
use Cwd;

our $VERSION= '3.01';

sub _start_helper {
	die q{ There is no method of '_start_helper'. };
}
sub _helper_get_options {
	my $self = shift;
	my $opts = shift || "";
	   $opts.= " o-output_path= h-help g-debug ";
	Getopt::Easy::get_options($opts);
	$O{output_path}=~s{\s+} []g if $O{output_path};
	if ($O{debug}) {
		$self->global->{flags}{-debug}= 1;
		$self->_setup_method(ref($self));
	}
	\%O;
}
sub helper_perl_path {
	require File::Which;
	$ENV{PERL_PATH} || File::Which::which('perl')
	|| die q{ Please set environment variable 'PERL_PATH'. };
}
sub helper_temp_dir {
	tempdir( CLEANUP=> 1 );
}
*helper_tempdir= \&helper_temp_dir;

sub helper_current_dir {
	Cwd::getcwd();
}
sub helper_is_platform {
	{ MSWin32=> 'Win32', MacOS=> 'MacOS' }->{$^O} || 'Unix';
}
sub helper_is_unix {
	helper_is_platform() eq 'Unix' ?  1: 0;
}
sub helper_is_win32 {
	helper_is_platform() eq 'Win32' ? 1: 0;
}
sub helper_is_macos {
	helper_is_platform() eq 'MacOS' ? 1: 0;
}
*helper_is_mac= \&helper_is_macos;

sub helper_yaml_load {
	require Egg::Plugin::YAML;
	my $self= shift;
	my $data= shift || croak q{ I want yaml data. };
	Egg::Plugin::YAML->yaml_load($data);
}
sub helper_stdout {
	require Egg::Util::STDIO;
	Egg::Util::STDIO->out(@_);
}
sub helper_stdin {
	require Egg::Util::STDIO;
	Egg::Util::STDIO->in(@_);
}
sub helper_load_rc {
	my $self= shift;
	my $pm  = shift || {};
	my $c   = $self->config;
	require Egg::Plugin::rc;
	my $rc= Egg::Plugin::rc::load_rc
	   ($self, ($c->{root} || $c->{start_dir})) || {};
	$rc->{author}     ||= $rc->{copywright} || "";
	$rc->{copywright} ||= $rc->{author}     || "";
	$rc->{headcopy}   ||= $rc->{copywright} || "";
	$rc->{license}    ||= 'perl';
	my %esc= ( "'"=> 'E<39>', '@'=> 'E<64>', "<"=> 'E<lt>', ">"=> 'E<gt>' );
	for (qw{ author copyright headcopy }) {
		$rc->{$_} ||= $ENV{LOGNAME} || $ENV{USER} || 'none.';
		$rc->{$_}=~s{([\'\@<>])} [$esc{$1}]gso;
	}
	@{$pm}{keys %$rc}= values %$rc;
	$pm;
}
sub helper_chdir {
	my $self= shift;
	my $path= $_[0] ? ($_[1] ? [@_]: $_[0]): croak q{ I want path. };
	$path= [$path, 0] unless ref($path) eq 'ARRAY';
	$self->helper_create_dir($path->[0]) if ($path->[1] && ! -e $path->[0]);
	print "= change dir : $path->[0]\n";
	chdir($path->[0]) || croak qq{$! : $path->[0] };
}
sub helper_create_dir {
	require File::Path;
	my $self= shift;
	my $path= $_[0] ? ($_[1] ? [@_]: $_[0]): croak q{ I want path. };
	$path= [$path] unless ref($path) eq 'ARRAY';
	File::Path::mkpath($path, 1, 0755);  ## no critic
}
sub helper_remove_dir {
	require File::Path;
	my $self= shift;
	my $path= $_[0] ? ($_[1] ? [@_]: $_[0]): croak q{ I want dir. };
	$path= [$path] unless ref($path) eq 'ARRAY';
	print "- remove dir : ". join(', ', @$path). "\n";
	File::Path::rmtree($path) || return 0;
}
sub helper_remove_file {
	my $self= shift;
	my $path= $_[0] ? ($_[1] ? [@_]: $_[0]): croak q{ I want file path. };
	$path= [$path] unless ref($path) eq 'ARRAY';
	for (@$path) { print "+ remove file: $_\n" if unlink($_) }
}
sub helper_read_file {
	require FileHandle;
	my $self= shift;
	my $file= shift || croak q{ I want file path. };
	my $fh  = FileHandle->new($file) || croak qq{ '$file' : $! };
	binmode $fh;
	my $value= join '', <$fh>;
	$fh->close;
	defined($value) ? $value: "";
}
*helper_fread= \&helper_read_file;

sub helper_save_file {
	require File::Spec;
	require File::Basename;
	my $self = shift;
	my $path = shift || croak q{ I want save path. };
	my $value= shift || croak q{ I want save value. };
	my $type = shift || 'text';
	my $base = File::Basename::dirname($path);
	if ($type=~m{^bin}i) {
		MIME::Base64->require;
		$$value= MIME::Base64::decode_base64($$value);
	}
	if (! -e $base || ! -d _) {
		$self->helper_create_dir($base) || die qq{ $! : $base };
	}
	my @path= split /[\\\/\:]+/, $path;
	my $file= File::Spec->catfile(@path);
	open FH, "> $file" || die qq{ File Open Error: $file - $! };  ## no critic
	binmode(FH);
	print FH $$value;
	close FH;
	if (-e $file) {
		print "+ create file: ${file}\n";
		if ($type=~m{^script}i or $type=~m{^bin_exec}i) {
			if ( chmod 0700, $file )  ## no critic
			   { print "+ chmod  0700: ${file}\n" }
		}
	} else {
		print "- create Failure : ${file}\n";
	}
	return 1;
}
sub helper_create_file {
	my $self = shift;
	my $data = shift || croak q{ I want data.  };
	my $param= shift || 0;
	my $path = $self->egg_var(($param || {}), $data->{filename})
	        || croak q{ I want data->{filename} };
	my $type = $data->{filetype} || "";
	my $value= $type=~m{^bin}i ? do {
		$data->{value};
	  }: $param ? do {
		$self->egg_var($param, \$data->{value}, $path) || "";
	  }: do {
		defined($data->{value}) ? $data->{value}: "";
	  };
	$self->helper_save_file($path, \$value, $type);
}
sub helper_create_files {
	my $self = shift;
	my $data = shift || croak q{ I want data.  };
	$data= [$data] unless ref($data) eq 'ARRAY';
	my $param= shift || 0;
	$self->helper_create_file($_, $param) for @$data;
}
sub helper_document_template {
	my $self= shift;
	$self->{helper_document_template}
	   ||= $self->helper_yaml_load(join '', <DATA>);
}
sub helper_valid_version_number {
	my $self= shift;
	my $version= shift || '0.01';
	$version=~m{^\d+\.\d\d+$}
	   || return $self->_helper_help('Bad format of version number.');
	$version;
}
sub helper_prepare_param {
	my $self= shift;
	my $pm  = shift || {};
	require Egg::Release;
	my $pname= $self->config->{project_name};
	$pm->{project_name} ||= $pname;
	$pm->{lib_dir}= "lib/${pname}";
	$pm->{lc_project_name}= lc($pname);
	$pm->{uc_project_name}= uc($pname);
	$pm->{ucfirst_project_name}= ucfirst($pname);
	$pm->{project_root}= $self->config->{root};
	$pm->{output_path} ||= $pm->{project_root};
	$pm->{dir} = $self->config->{dir};
	$pm->{root}= sub { $self->config->{root} };
	$pm->{year}= sub { (localtime time)[5]+ 1900 };
	$pm->{perl_path}= sub { $self->helper_perl_path };
	$pm->{gmtime_string}= sub { gmtime time };
	$pm->{created} ||= "Egg::Helper v". Egg::Helper->VERSION;
	$pm->{revision} = '$'. 'Id'. '$';
	$pm->{module_version} ||= 0.01;
	$pm->{perl_version}= $] > 5.006 ? sprintf "%vd", $^V : sprintf "%s", $];
	$pm->{egg_release_version}= Egg::Release->VERSION;
	if (my $egg_inc= $ENV{EGG_INC}) {
		$pm->{egg_inc}= qq{\nuse lib qw(}
		 . join(' ', split /\s*[\, ]\s*/, $egg_inc). qq{);};
	} else {
		$pm->{egg_inc}= ""; ## "\nuse lib qw( ../../lib ../lib ./lib );";
	}
	$self->helper_load_rc($pm);
	my $data= $self->helper_document_template;
	$pm->{document}= sub {
		my($proto, $param, $fname)= @_;
		my $pod_text= $data->{pod_text};
		$proto->egg_var($param, \$pod_text, ($fname || ""));
	  };
	my %param_cache;
	$pm->{dist}= sub {
		my($proto, $param)= splice @_, 0, 2;
		my $fname= $proto->_conv_unix_path(@_) || return "";
		return $param_cache{$fname} if $param_cache{$fname};
		my $tmp= $fname;
		$tmp=~s{^[A-Za-z]\:+} [];
		for my $regex
		  (($pm->{output_path} || $pm->{project_root}), $pm->{module_name}) {
			next unless $regex;
			$regex= quotemeta($regex);
			$tmp=~s{^$regex} [];
			$tmp=~s{^\.?/+}  [];
		}
		$tmp=~s{^lib}   [];
		$tmp=~s{^\.?/+} [];
		$tmp=~s{\.pm$}  [];
		$tmp=~s{^(?:\:|\-)+} []o;
		$param_cache{$fname}= join '::', (split /\/+/, $tmp);
	  };
	$pm;
}
sub helper_prepare_param_module {
	my $self= shift;
	my $pm  = shift || {};
	my $name= ref($_[0]) eq 'ARRAY' ? $_[0]: \@_;
	my $output_path= $pm->{output_path}
	   || $self->config->{output_path} || croak q{ 'output_path' is empty. };
	my @path;
	for (@$name) {
		my @n= split /\:+/, $_;
		splice @path, scalar(@path), 0, @n;
	}
	$pm->{module_name}    = join('-',  @path);
	$pm->{module_filepath}= join('/',  @path). '.pm';
	$pm->{module_distname}= join('::', @path);
	$pm->{module_basedir} = join('/',  @path[0..($#path- 1)]);
	$pm->{module_filename}= $pm->{module_filepath};
	$pm->{module_filename}=~s{^$pm->{module_basedir}} [];
	$pm->{module_filename}=~s{^/} [];
	$pm->{target_path}    = "${output_path}/$pm->{module_name}";
	$pm->{lib_dir}        = "${output_path}/$pm->{module_name}/lib";
	$pm->{lib_basedir}    = "$pm->{lib_dir}/$pm->{module_basedir}";
	$pm;
}
sub helper_generate_files {
	my $self= shift;
	my $attr= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $pm= $attr->{param} || croak q{ I want generate param. };
	$self->helper_chdir($attr->{chdir}) if $attr->{chdir};
	eval {
		if (my $dirs = $attr->{create_dirs})
		   { $self->helper_create_dir($_) for @$dirs }
		if (my $files= $attr->{create_files})
		   { $self->helper_create_file($_, $pm) for @$files }
		if (my $code = $attr->{create_code})
		   { $code->($self, $attr) }
		if ($attr->{makemaker_ok})
		   { $self->_helper_execute_makemaker }
		if (my $message= $attr->{complete_msg}) {
			print $message. "\n\n";
		} else {
			print "File generate is complete.\n\n";
		}
	  };
	$self->helper_chdir($self->config->{start_dir}) if $attr->{chdir};
	my $error= $@ || return 1;
	my $msg;
	if (my $err= $attr->{errors}) {
		$msg= $err->{message} || "";
		if (my $dirs = $err->{rmdir})  { $self->helper_remove_dir($dirs) }
		if (my $files= $err->{unlink}) { $self->helper_remove_file(@$files) }
	}
	$msg ||= '>> File generate error';
	die "${msg}:\n $error";
}
sub helper_get_dbi_attr {
	shift;  {
	  table   => ($ENV{EGG_DBI_TEST_TABLE} || 'egg_release_dbi_test'),
	  dsn     => ($ENV{EGG_DBI_DSN}      || ""),
	  user    => ($ENV{EGG_DBI_USER}     || ""),
	  password=> ($ENV{EGG_DBI_PASSWORD} || ""),
	  host    => ($ENV{EGG_DBI_HOST}     || ""),
	  port    => ($ENV{EGG_DBI_PORT}     || ""),
	  options => ($_[1] ? {@_}: ($_[0] || {})),
	  };
}
sub helper_http_request {
	require HTTP::Request::Common;
	my $self   = shift;
	my $method = uc(shift) || 'GET';
	my $uri    = shift || '/request';
	no strict 'refs';  ## no critic.
	my $q= &{"HTTP::Request::Common::$method"}( $uri=> @_);
	my $result= $q->as_string;
	$result=~s{^(?:GET|POST)[^\r\n]+\r?\n} [];
	$result=~s{Content\-Length\:\s+(\d+)\r?\n}
	                  [ $ENV{CONTENT_LENGTH}= $1; "" ]e;
	$result=~s{Content\-Type\:\s+([^\n]+)\r?\n}
	                  [ $ENV{CONTENT_TYPE}= $1; "" ]e;
	$result;
}
sub _helper_execute_makemaker {
	my($self)= @_;
	return unless ($self->helper_is_unix
	   or (exists($ENV{EGG_MAKEMAKER}) and $ENV{EGG_MAKEMAKER}) );
	Module::Install->require;
	if ($@ and $@=~m{^Can\'t\s+locate\s+(?:inc[/\:]+)?Module[/\:]+Install(?:\.pm)?\s+} ) {
		warn "\nWarning: Module::Install is not installed !!\n";
		return 1;
	}
	eval{
		system('perl Makefile.PL') and die $!;
		system('make manifest')    and die $!;
		system('make')             and die $!;
		system('make test')        and die $!;
	  };
	if (my $err= $@) { print $err }
	eval{ `make distclean` };
}
sub _helper_help {
	my $self= shift;
	my $msg = shift || "";
	$msg= ">> ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl egg_helper.pl [MODE] -h

END_HELP
}
sub _conv_unix_path {
	my $self= shift;
	my $path= shift || return "";
	return $path if $self->helper_is_unix;
	my $regixp= $self->helper_is_mac ? qr{\:}: qr{\\};
	$path=~s{$regixp+} [/]g;
	$path;
}

1;

=head1 NAME

Egg::Helper::Util::Base - Utility for a helper module.

=head1 DESCRIPTION

It is a utility class for the helper module.

=head1 METHODS

The method of this module can be used in the shape succeeded to to L<Egg::Helper>.

These methods are the one having aimed at use from the helper module.

=head2 helper_perl_path

Passing perl is acquired and returned by L<File::Which>.

However, if PERL_PATH is set in the environment variable, the value is returned.

  my $perl_path= Egg::Helper->helper_perl_path;

=head2 helper_temp_dir

The work directory is temporarily made from L<File::Temp>, and the passing is 
returned.

When the process is annulled, the made directory is deleted by the automatic 
operation.

  my $tempdir= Egg::Helper->helper_temp_dir;

=over 4

=item * Alias = helper_tempdir

=back

=head2 helper_current_dir

A current now passing is acquired and returned by L<Cwd>.

  my $current_dir= Egg::Helper->helper_current_dir;

=head2 helper_is_platform

The name of the platform under operation is returned.

It is only Win32, MacOS, and Unix to be returned.

All Unix is returned if it is Win32, MacOS, and it doesn't exist.

=head2 helper_is_unix

The platform under operation returns and Win32 and MacOS return true if it is not.

=head2 helper_is_win32

If the platform under operation is Win32, true is returned.

=head2 helper_is_macos

If the platform under operation is MacOS, true is returned.

=over 4

=item * helper_is_mac

=back

=head2 helper_yaml_load ([YAML_TEXT])

The text of the YAML form is converted into data and it returns it.

  my $hash= Egg::Helper->helper_yaml_load($yaml_text);

=head2 helper_stdout ([ARGS])

ARGS is passed to the out method of L<Egg::Util::STDIO>, and the result is returned.

=head2 helper_stdin ([ARGS])

ARGS is passed to the in method of L<Egg::Util::STDIO>, and the result is returned.

=head2 helper_load_rc ([HASH_REF])

The rc file arranged by L<Egg::Plugin::rc> for the project is read.

And, it read from the rc file, and author, copywright, headcopy, and license are
set to HASH_REF and it returns it.

=head2 helper_chdir ([PATH_STR], [BOOL])

The current directory is moved to PATH_STR.
And, the moving destination is output to STDOUT.

It makes it if there is no moving destination when BOOL is given.

  $helper->helper_chdir('/path/to/move', 1);

=head2 helper_create_dir ([PATH_LIST])

The directory of PATH_LIST is made and the passing is output to STDOUT.

There is exist former directory not worrying because it uses 'mkpath' of L<File::Path>.

  $helper->helper_create_dir('/path/to/hoge', '/path/to/booo');

=head2 helper_remove_dir ([PATH_LIST])

The directory of PATH_LIST is deleted and the passing is output to STDOUT.
L<File::Path> Because drinking 'rmtree' is used, all subordinate's directories
are deleted.

  $helper->helper_remove_dir('/path/to/hoge', '/path/to/booo');

=head2 helper_remove_file ([PATH_LIST])

All files of PATH_LIST are deleted and the passing is output to STDOUT.
The deletion fails if passing specified this is specializing in the file is a
file and doesn't exist.

  $helper->helper_remove_file('/path/to/hoge.txt', '/path/to/booo.tmp');

=head2 helper_read_file ([FILE_PATH])

The content is returned reading FILE_PATH. Because binmode is always done, it is
possible to read even by the binary.

  my $value= $helper->helper_read_file('/path/to/hoge.txt');

=over 4

=item * Alias = helper_fread

=back

=head2 helper_save_file ([PATH], [SCALAR_REF], [TYPE])

The file is generated.

PATH is passing of the generation file.

SCALAR_REF is a content of the generated file.
It gives it by the SCALAR reference.

After it generates it, the execution attribute of 0700 is set if TYPE is script
or 'bin_exec'.

If it is a name that TYPE starts by bin, it puts it into the state to restore
SCALAR_REF with L<MIME::Base64>.

If the directory of the generation place doesn't exist, 'helper_create_dir' is
done and the directory is made.

And, the generation situation is output to STDOUT.

  $helper->helper_save_file('/path/to/', $value, 'text');

The file is always written with binmode. 

=head2 helper_create_file ([HASH_REF], [PARAM])

'helper_save_file' is done according to the content of HASH_REF.

HASH_REF is HASH reference with the following keys.

  filename ..... It corresponds to PATH of 'helper_save_file'.
  value    ..... It corresponds to SCALAR_REF of 'helper_save_file'.
  filetype ..... It corresponds to TYPE of 'helper_save_file'.

Moreover, it is L<Egg::Util> if it is a name that giving PARAM and filetype start
by bin and it doesn't exist. It 'drinks egg_var'.

  $helper->helper_create_file({
    filename => '<e.die.etc>/hoge.txt',
    value    => 'Create OK',
    filetype => 'text',
    }, $e->config );

=head2 helper_create_files ([CREATE_LIST], [PARAM])

Two or more files are generated with helper_create_file based on CREATE_LIST.
In CREATE_LIST, it is ARRAY always reference, and each element is HASH_REF passed
to helper_create_file.

PARAM extends to helper_create_file as it is.

  $helper->helper_create_files
    ([ $helper->helper_yaml_load( join '', <DATA> ) ])

=head2 helper_document_template

The document sample to bury it under the content when the module is generated is
returned.

  my $sample= $helper->helper_document_template;

=head2 helper_valid_version_number ([VERSION_NUM])

It examines whether VERSION_NUM is suitable as the version number of the module.

'_helper_help' is called in case of not being suitably.

When VERSION_NUM is omitted, '0.01' is returned.

  my $version= $helper->helper_valid_version_number($o->{version});

=head2 helper_prepare_param ([PARAM])

Each parameter needed when the file is generated is set in PARAM and it returns it.

PARAM is omissible. Thing made HASH reference when giving it.

  my $param= $helper->helper_prepare_param;
  $helper->helper_create_files($data, $param);

=head2 helper_prepare_param_module ([PARAM])

Each parameter needed when the module is generated is set in PARAM and it returns it.

  my $param= $helper->helper_prepare_param;
  $helper->helper_prepare_param_module($param);
  $helper->helper_create_files($data, $param);

=head2 helper_generate_files ([HASH_REF])

A series of file generation processing according to the content of HASH_REF is
done.

HASH_REF is HASH reference of the following content.
Only param is indispensable.

=over 4

=item * param

It is a parameter acquired with 'helper_prepare_param' etc.

=item * chdir

It extends to 'helper_chdir'. When the flag is given, it does by the ARRAY reference.

=item * create_dirs

It is ARRAY reference passed to 'helper_create_dir'.

=item * create_files

It is ARRAY reference passed to 'helper_create_files'.

=item * create_code

It is CODE reference for doing on the way as for some processing.

=item * makemaker_ok

After the file is generated, '_helper_execute_makemaker' is done.

=item * complete_msg

It is a message after processing ends.

=item * errors

It is a setting when the error occurs by processing the above-mentioned and 
HASH reference.

=over 4

=item * message

Message when error occurs.

=item * rmdir

List of directory passed to 'helper_remove_dir'.

=item * unlink

List of file passed to 'helper_remove_file'.

=back

=back

=head2 helper_get_dbi_attr ([HASH])

The setting concerning DBI for Egg is acquired from the environment variable.
This is the one having aimed at the thing used in the test of the package.

The following environment variables are acquired and the HASH reference is 
returned.

  {
    table   => ($ENV{EGG_DBI_TEST_TABLE} || 'egg_release_dbi_test'),
    dsn     => ($ENV{EGG_DBI_DSN}      || ""),
    user    => ($ENV{EGG_DBI_USER}     || ""),
    password=> ($ENV{EGG_DBI_PASSWORD} || ""),
    options => ($_[1] ? {@_}: ($_[0] || {})),
    };

=head2 helper_http_request ([REQUEST_METHOD], [URI], [PARAM])

When emulation is done in the code, the WEB request is convenient for this in
the package test.

L<HTTP::Request::Common> is done, and 'as_string' of L<HTTP::Request> is received.
And, after environment variable CONTENT_LENGTH and CONTENT_TYPE are set,
the fragment of as_ string is returned.

=head2 _helper_execute_makemaker

Perl Makefile.PL etc. are executed at the command line level in the current
directory.

When the error occurs, the exception is not generated. It only reports on the
error to STOUT.

Moreover, helper_is_unix returns false and if environment variable EGG_MAKEMAKER
is also undefined, it returns it without doing anything.

When L<Module::Install> is not installed, only warning is vomited and nothing is
 done.

=head2 _helper_help ([MSG])

Help of default is displayed.

After it helps, it is displayed in the part when MSG is passed.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,
L<Egg::Plugin::YAML>,
L<Egg::Plugin::rc>,
L<Egg::Util::STDIO>,
L<Egg::Exception>,
L<Cwd>,
L<File::Basename>,
L<File::Path>,
L<File::Spec>,
L<File::Temp>,
L<File::Which>,
L<FileHandle>,
L<Getopt::Easy>,
L<HTTP::Request::Common>,
L<MIME::Base64>,
L<UNIVERSAL::require>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut




__DATA__
pod_text: |
  # Below is stub documentation for your module. You'd better edit it!
  
  =head1 NAME
  
  < e.dist > - Perl extension for ...
  
  =head1 SYNOPSIS
  
    use < e.dist >;
    
    ... tansu, ni, gon, gon.
  
  =head1 DESCRIPTION
  
  Stub documentation for < e.dist >, created by < e.created >
  
  Blah blah blah.
  
  =head1 SEE ALSO
  
  L<Egg::Release>,
  
  =head1 AUTHOR
  
  < e.author >
  
  =head1 COPYRIGHT AND LICENSE
  
  Copyright (C) < e.year > by < e.copyright >.
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version < e.perl_version > or,
  at your option, any later version of Perl 5 you may have available.
  
  =cut
