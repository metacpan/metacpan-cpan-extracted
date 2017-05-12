package MasonX::Request::HTMLTemplate;

#use vars qw(@ISA);

use HTML::Mason 1.16;
use HTML::Mason::Request;
use HTML::Template::Extension;
use File::Spec;
use Params::Validate qw(:all);

$MasonX::Request::HTMLTemplate::VERSION	= '0.06';

#@ISA = qw(HTML::Mason::Request HTML::Template::Extension);
use base qw(HTML::Mason::Request HTML::Template::Extension);

# definition of localizated error string for unexistent template
my $err_tmpl_notfound_string = {
	'it' => q|
				<h2>Modello per il componente <b>%comp_name%</b> 
				non trovato.</h2>
						Il modello mancante dovrebbe essere posto 
						nel percorso <br><b><pre>%tmpl_file_path%</pre></b>
				<p>Contattate il webmaster
			|,
	'en' => q|
				<h2>Unable to find template for <b>%comp_name%</b> 
				.</h2>
						The missing template should be located in the path
						<br><b><pre>%tmpl_file_path%</pre></b>
				<p>Please contact webmaster
			|,
	'fr' => q|
				<h2>Unable to find template for <b>%comp_name%</b> 
				.</h2>
						The missing template should be located in the path
						<br><b><pre>%tmpl_file_path%</pre></b>
				<p>Please contact webmaster
				<p>Please traslate it in french language
			|,
};

Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

__PACKAGE__->valid_params(
					template_base_path 	=> { 
											parse =>'string',
											type => Params::Validate::SCALAR,
											optional => 1,
											default => 'undef',
										},
					default_language 	=> { 
											parse =>'string',
											type => Params::Validate::SCALAR,
											optional => 1,
											default => 'en',
										}
						);

my %fields =
    (
     autoDeleteHeader => 0,
     file               => '',
     args               => {},
     plugins=>["SLASH_VAR","CSTART","HEAD_BODY","IF_TERN"],
     absolute_path      => 0,
     );


sub new {
	my $class = shift;
	my $htmpl = $class->HTML::Template::Extension::new(%fields);
	$class->alter_superclass( &{"${class}::_alter_superclass"} );
	my $mason = $class->SUPER::new(@_);
	$self = {%{$mason},%{$htmpl}};
    bless $self, $class;
    while (my ($key,$value) = each(%options)) {
        if (exists($fields{$key})) {
            $self->{$key} = $value if ($key ne 'file');
        } else {
            die ref($self) . "::new: invalid option '$key'\n";
        }
    }
    $self->filename($options{file}) if (exists($options{file}));
	return $self;
}

sub print_template {
	my $self 			= shift;
	my $c_args			= shift || {};
	my $tmpl_file_path  = shift || $self->callers(0)->name;
	$tmpl_file_path		= $self->_convFileName($tmpl_file_path);
	# merging $c_args and items
	my $html_args 		= { %{$self->items}, %{$c_args} };
	my $html			= $self->html($html_args,$tmpl_file_path);
	$self->print($html) if (defined $html);
}
sub items {
	# return a reference to an hash with union of %ARGS, $self->{args},
	# the traslaslation of session variable using _convStructToHash and,
	# for each elements of this hash, items in the form "key=value" => 1
	my $self 		= shift;
	my $more_args 	= shift || {};

	my %self_args	= $self->{args} ? %{$self->{args}} : {};
	# merging client args + add_template_args + more_args (from WithApacheSession)
	$ret = {%{$more_args} , %{$self->request_args} , %self_args};

	# add key=value => 1 to be used with TMPL_IF or with
	# HTML::Template::Extension::IF_TERM
	my @keys = keys %$ret;
	foreach $key (@keys) {
		my $value = $ret->{$key};
	  	if (ref($value) eq 'ARRAY') {
	   		# is an array. Traslate and add all elements in form key=value => 1
	   		foreach (@{$value}) { $ret->{"$key=$_"} = 1; }
		} else {
	   		# scalar...ok...single element.
	   		$ret->{"$key=$value"} = 1;
	  	}
	}
	return $ret;
}
sub filename {
  my $self = shift;
  if (@_) {
		my $filename = $self->_tmplFilePath(shift);
    $self->SUPER::filename($self->_tmplFilePath(shift)) if (defined $filename);
	}
	return $self->{filename};
}

sub file {
	return shift()->filename(@_);
}

sub html {
	# overraide defalt html method to support base_root_dir
	# and return html error string if selected template doesn't exist.
	my $self = shift;
	my $args = shift;
	my $file = shift;
	# define lang bypass cache
	if (exists($args->{lang})) {
		$self->{default_language} = $args->{lang};
	}
	if (defined $file) {
		my $file = $self->_tmplFilePath($file);
		if (-e $file) {
			return $self->SUPER::html($args,$file);
		} else {
			# template file don't exists...print error to client
			$self->_throw_error_tmpl_notfound($file);
			# undef to stop print above.
			return undef;
		}
	} else {
		return $self->SUPER::html($args);
	}
}

sub add_template_args() {
	my $self		= shift;
	my %args		= @_;
	$self->{args}	= {%{$self->{args}}, %args };
	return @_;
}

sub template_arg() {
	my $self		= shift;
	my $key			= shift;
	return $self->{args}->{$key};
}

sub absolute_path {
	# the template file is chroot(/) or chroot(mason_root_component_path)?
	my $s=shift; return @_ ? ($s->{absolute_path}=shift) : $s->{absolute_path};
}

sub _alter_superclass() {
	#return 	$MasonX::Request::WithApacheSession::VERSION 
    #      		? 'MasonX::Request::WithApacheSession' 
	return			$HTML::Mason::ApacheHandler::VERSION 
               		? 'HTML::Mason::Request::ApacheHandler' 
                    : $HTML::Mason::CGIHandler::VERSION 
                   		? 'HTML::Mason::Request::CGI' 
                   		: 'HTML::Mason::Request';
}

sub _tmplFilePath {
	# convert the file path based on absolute/relative path
	# and to base_dir and language
	my $self			= shift;
	my $comp_name		= shift || $self->current_comp->name;
	my $abs_path;
	if ($self->absolute_path) {
		# client request that the param it set is absolute...
		# try only to see if exists a language version
		$abs_path = $comp_name;
	} else {
		# built absolute path
		my $base_root	= $self->interp->comp_root;
		my $tbp			= $self->{template_base_path} eq 'undef' ? '' :
										$self->{template_base_path};
		if (File::Spec->file_name_is_absolute($comp_name)) {
			$abs_path	= File::Spec->catfile($base_root,$tbp,$comp_name);
		} else {
			my $comp_dir= $self->callers(0)->path;
			(undef,$comp_dir,undef) = File::Spec->splitpath($comp_dir);
			$abs_path	= File::Spec->catfile($base_root,$tbp,$comp_dir,$comp_name);
		}
	}
	return $self->_tmplLang($abs_path);
}

sub _tmplLang {
	# try to see if exists file for language selected
	my $self			= shift;
	my $abs_path		= shift;
	my ($volume,$dirs,$file) = File::Spec->splitpath( $abs_path ); 
	my ($fn,$ext) 		= split(/\./,$file);
	my $file_lang		= $fn . '.' . $self->{default_language} . '.' . $ext;
	my $path_lang		= File::Spec->catpath($volume,$dirs,$file_lang);
	$path_lang			= File::Spec->canonpath($path_lang);
	# return it if exists language file
	return $path_lang if (-e $path_lang);
	# else return the original after a cleanup
	return File::Spec->canonpath($abs_path);
}

sub _convFileName {
	# convert component name in template file subst extention with ".htt"
	my $self 			= shift;
	my $abs_path        = shift;
	my ($volume,$dirs,$file) = File::Spec->splitpath( $abs_path );
	my ($fn,$ext)       = split(/\./,$file);
	return $abs_path if ($ext !~ /^m(pl|htm|html)$/);
	$file				= "$fn.htt";
	return File::Spec->canonpath(File::Spec->catpath($volume,$dirs,$file));
}

sub _print_html() {
	my $self 	= shift;
	return "<HTML>\n<HEAD>\n</HEAD>\n<BODY>\n" . shift() . "\n</BODY>\n</HTML>";
}

sub _throw_error_tmpl_notfound {
	my $self			= shift;
	my $tmpl_file_path	= shift;
	my $comp_name		= $self->callers(0)->path;
	my $htmlerr = $self->_print_html($self->_err_tmpl_notfound);
	$self->scalarref(\$htmlerr);
	$self->print($self->html({	comp_name 		=> $comp_name , 
								tmpl_file_path 	=> $tmpl_file_path}));
}

sub _err_tmpl_notfound {
	# return localized error string for unexistent template
	# see err_tmpl_notfound_string hash in the header of this package
	return exists($err_tmpl_notfound_string->{$self->{default_language}}) ? 
						$err_tmpl_notfound_string->{$self->{default_language}} : 
						$err_tmpl_notfound_string->{en};
}

1;
