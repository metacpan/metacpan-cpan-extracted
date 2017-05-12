package JavaScript::V8::Handlebars;

use strict;
use warnings;

our $VERSION = '0.06';

use File::Slurp qw/slurp/;
use File::Spec;
use File::Find ();
use File::ShareDir ();

use JSON ();
use JavaScript::V8;

my $module_dir = File::ShareDir::module_dir( __PACKAGE__ );
my ( $LIBRARY_PATH ) = glob "$module_dir/handlebars*.js"; # list context avoids global state

###############
# CLASS METHODS
sub import {
	my( $class, %opts ) = @_;
	if( $opts{ library_path } ) { 
		if( -r $opts{ library_path } ) {
			$LIBRARY_PATH = $opts{ library_path };
		}
		else {
			die "Can't read path [$opts{library_path}] (should be readable js file!)";
		}
	}
}

#TODO These should also work as object methods and return the file the object is actually using..
sub handlebars_path { $LIBRARY_PATH }
sub handlebars_code { slurp $LIBRARY_PATH }
###############

sub new {
	my( $class, %opts ) = @_;

	my $self = bless {}, $class;

	$self->_build_context(%opts);

	# Currently must be absolute or relative to the cwd
	if( $opts{preload_libs} ) {
		for( @{ $opts{preload_libs} } ) {
			$self->eval_file( $_ );
		}
	}

	return $self;
}

sub _build_context {
	my( $self, %opts ) = @_;

	my $c = $self->{c} = JavaScript::V8::Context->new;
	$self->_add_console;


	my $handlebars_path = $opts{library_path} || $LIBRARY_PATH;

	$self->eval_file( $handlebars_path );

	my $hb = 'Handlebars';
	# Store subrefs for each javascript method
	for my $meth (qw/precompile registerHelper registerPartial template compile escapeExpression/ ) {
		# lots of Handlebars methods operate on 'this' so we have to bind our
		# function calls to the object in use
		$self->{$meth} = $self->eval( "$hb.$meth.bind( $hb )" );
	}
}

sub _add_console {
	my( $self ) = @_;

	$self->c->bind( console => {
		log => sub {
			my $json = JSON->new->pretty->utf8;
			for( @_ ) {
				if( ref $_ ) {
					print $json->encode( $_ );
				}
				else {
					print "$_\n";
				}
			}
		}
	} );
}

sub c {
	return $_[0]->{c};
}
sub eval {
	my( $self, $code, $origin ) = @_;
	$origin ||= join " ", (caller(1))[0..3]; #package, filename, line, subroutine

	my $ret = $self->{c}->eval($code, $origin);

	die $@ if $@;
	return $ret;
}

sub eval_file {
	my( $self, $file ) = @_;

	$self->eval( scalar slurp($file), $file ); 
}

sub escape_expression {
	my $self = shift;
	return $self->{escapeExpression}->(@_);
}

sub precompile {
	my( $self, $template, $opts ) = @_;

	return $self->{precompile}->($template, $opts);
}
sub precompile_file {
	return $_[0]->precompile( scalar slurp($_[1]), $_[2] );
}

sub compile {
	my( $self, $template, $opts ) = @_;

	return $self->{compile}->($template, $opts);
}
sub compile_file {
	return $_[0]->compile( scalar slurp($_[1]), $_[2] );
}


sub register_helper {
	my( $self, $name, $code, $origin ) = @_;

	if( ref $code eq 'CODE' ) {
		$self->{registerHelper}->( $name, $code );
	}
	elsif(ref $code eq '') {
		# There seems to be no good way to stay in javascript land here,
		# so we create a perl function from the helper and register it instead.
		# Parens force 'expression' context so the function reference is returned.
		my $fnct = $self->eval( "( $code )", $origin || [caller]->[1] );
		$self->{registerHelper}->( $name, $fnct );
	}
	else {
		die "Bad helper: should be CODEREF or JS source [$code]";
	}

	return 1;
}

sub register_partial_file {
	my( $self, $name, $file ) = @_;
	
	die "Failed to read [$file]" unless -r $file and -f $file;

	return $self->register_partial( $name, scalar slurp $file );
}

sub register_partial {
	my( $self, $name, $tpl ) = @_;

	if( ref $tpl eq '' ) {
		$tpl = $self->compile( $tpl );
	}

	if( ref $tpl eq 'CODE') {
		$self->{registerPartial}->( $name, $tpl );
	}
	else {
		die "Bad partial template: should be CODEREF or template source [$tpl]";
	}

	return 1;
}

sub template {
	my( $self, $template ) = @_;

	if( ref $template eq '' ) {
		#Parens force 'expression' context
		return $self->{template}->($self->eval( "($template)" )); 
	}
	elsif( ref $template eq 'HASH' ) {
		return $self->{template}->( $template );
	}
	else { die "Bad arg [$template] (string or hash)" }
}


sub render_string {
	my( $self, $template, $env ) = @_;

	return $self->compile( $template )->( $env );
}


sub add_template {
	my( $self, $name, $template ) = @_;

	$self->{template_code}{$name} = $self->precompile( $template );

	return $self->{templates}{$name} = $self->compile( $template );
}

sub add_template_file {
	my( $self, $file, $name ) = @_;

	die "Failed to read $file $!" unless -e $file and -r $file;
	unless( defined $name ) {
		$name = (File::Spec->splitpath($file))[2]; #Filename
		$name =~ s/\..*//; #Remove extension
	}
	
	$self->add_template( $name, scalar slurp $file );
}

sub add_template_dir {
	my( $self, $start_dir, $ext ) = @_;
	$ext ||= 'hbs';

	die "Failed to find [$start_dir]" unless -r $start_dir; #TODO Should this be fatal or a warning?

	File::Find::find( { 
		no_chdir => 1,
		wanted => sub {
			return unless -f;
			return unless /\.$ext$/;
			warn "Can't read $_" and return unless -r;

			my $name = File::Spec->abs2rel( $_, $start_dir );
				$name =~ s/\..*$//; #Remove extension

			if( $File::Find::dir =~ /(^|\W)partial(\W|$)/ ) {
				$self->register_partial_file( $name, $_ );
			}
			else {
				$self->add_template_file( $_, $name );
			}
		},
	}, $start_dir );

	return 1; #We got this far we suceeeded?
}

sub execute_template {
	my( $self, $name, $args ) = @_;

	return $self->{templates}{$name}->( $args );
}

sub bundle {
	my( $self ) = @_;

	my $out = "var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};\n";

	while( my( $name, $template ) = each %{ $self->{template_code} } ) {
		$out .= "templates['$name'] = template( $template );\n";
	}

	return $out;
}



1;

__END__

=head1 NAME

JavaScript::V8::Handlebars - Compile and execute Handlebars templates via the actual JS library

=head1 SYNOPSIS

	use JavaScript::V8::Handlebars;
	#use JavaScript::V8::Handlebars ( library_path => "/path/to/handlebars.js" );

	my $hbjs = JavaScript::V8::Handlebars->new;

	print $hbjs->render_string( "Hello {{var}}", { var => "world" } );

	my $template = $hbjs->compile_file( "template.hbs" );
	print $template->({ var => "world" });

	$hbjs->add_template_dir( './templates' );

	open my $oh, ">", "template.bundle.js" or die $!;
	print $oh $hbjs->bundle;
	close $oh;

=head1 METHODS

=head2 Package Methods

=over 4

=item use JavaScript::V8::Handlebars ( [library_path => "/path/to/handlebars.js"] );

When C<use>ing the library you may pass an optional path to a (full) handlebars.js file to use instead of the one it comes bundled with.

=item JavaScript::V8::Handlebars->handlebars_path

Returns the path to the handlebars.js file, set at the package level. 
Note that this may be overridden on a per object basis and can be changed after an object is created.

=item JavaScript::V8::Handlebars->handlebars_code

Returns the complete source of the handlebars.js file specified as above. 

=back

=head2 Object Methods

=over 4

=item $hbjs->new(%opts)

Arguments:

=over 4

=item library_path => $path

Path to the specific handlebars.js file you want to use.

=item preload_libs => [qw/paths here/]

Arrayref of JS filenames you want to evaluate when you create this object

=back

=item $hbjs->c()

Returns the internal JavaScript::V8 object, useful for executing javascript code in the context of the module.

=item $hbjs->eval_file($javascript_filename)

=item $hbjs->eval($javascript_string)

Wrapper function for C<$hbjs->c->eval> that checks for errors and throws an exception.

=item $hbjs->precompile_file($template_filename)

=item $hbjs->precompile($template_string)

Takes a template and translates it into the javascript code suitable for passing to the C<template> method.

=item $hbjs->compile_file($template_filename)

=item $hbjs->compile($template_string)

Takes a template and returns a subref that takes a hashref containing variables as an argument and returns the text of the executed template.

=item $hbjs->register_helper( $name, $js_code | $coderef )

Takes a name to store the helper under as well as either a perl code reference or a string of javascript to be compiled. 
These helpers can then be referred to from other templates via the standard Handlebars syntax.

=item $hbjs->template( $compiled_javascript_string | $compiled_perl_object )

Takes a precompiled template datastructure and returns a subref ready to be executed.

=item $hbjs->render_string( $template_string, \%context_vars )

Wrapper method for compiling and then executing a template passed as a string.

=item $hbjs->add_template_dir( $directory, [$extension] )

Recurses through a specified directory looking for each file that matches .$extension, which defaults to hbs. For each file it finds it calls 
add_template_file with a name based on the path relative to the template $directory
Ex. "templates/foo/bar.hbs" is stored under the name as "foo/bar" 

If the file found inside a directory named 'partial(s)' then registered_partial_file is called instead with a name derived in the same way as described above.

=item $hbjs->add_template_file( $filename, [$name] )

Compiles and caches the specified filename so it's available for later execution or bundling.
Takes an optional $name argument which specifies the name to internally store the template as, 
if omitted the name is set to the filename portion of the path with any extension removed.

=item $hbjs->add_template( $name, $template_string )

Takes a template, compiles it and adds it to the internal store of cached templates for C<execute_template> to use. 

=item $hbjs->execute_template( $name, \%context_vars )

Executes a cached template.

=item $hbjs->bundle()

Returns a string of javascript consisting of all the templates in the cache ready for execution by the browser.

=item $hbjs->safeString($string)

Whatever the original Handlebar function does.

=item $hbjs->escapeString ($string)

Whatever the original Handlebar function does.

=item $hbjs->register_partial_file($name, $filename)

Registers a partial with name $name from a file named $filename

=item $hbjs->register_partial($name, $template_string)

Registers a partial named $name with the code in $template_string and makes it globally available to templates.

=back

=head1 AUTHOR

Robert Grimes, C<< <rmzgrimes at gmail.com> >>

=head1 BUGS

Please report and bugs or feature requests through the interfaces at L<https://github.com/rmzg/JavaScript-V8-Handlebars>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc JavaScript::V8::Handlebars


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robert Grimes.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<https://github.com/rmzg/JavaScript-V8-Handlebars>, L<http://handlebarsjs.com/>

=cut
