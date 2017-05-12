package IkiWiki::Plugin::syntax;

use warnings;
use strict;
use Carp;
use utf8;
use Data::Dumper;

use IkiWiki 2.00;

use IkiWiki::Plugin::syntax::gettext;   # fake gettext for the IkiWiki old version
use IkiWiki::Plugin::syntax::Simple;    # the last option
use IkiWiki::Plugin::syntax::X;

our $VERSION    =   '0.25';
our $_syntax    =   undef;

my  %engine_parameters = (
    'Simple'    =>  undef,
    'Kate'      =>  undef,
    'Vim'       =>  undef,
);
my  $use_template   =   0;

# Module implementation here
sub import { #{{{
    ### Define the hooks into ikiwiki ...
    hook(type => 'checkconfig', id => 'syntax', call => \&checkconfig);
	hook(type => "preprocess", id => "syntax", call => \&preprocess);
} # }}}

sub checkconfig {
    
    ### select an engine from the global ikiwiki configuration
    #
    my  $engine = $IkiWiki::config{syntax_engine} || q(Simple);

    ### Read global parameters ...
    $use_template = $IkiWiki::config{syntax_use_template} || 0;

    # search for special parameters (unused)
    foreach my $engine_name (keys %engine_parameters) {
        my  $key    =  "syntax_" . lc($engine_name);
        if (exists $IkiWiki::config{$key}) {
            $engine_parameters{$engine_name} = $config{$key};
        }
    }

    _change_engine( $engine, %{ $engine_parameters{$engine} } );

    return;            
}

sub _change_engine {
    my  ($engine_name, %engine_params) = @_;

    # close the old engine 
    if (defined $_syntax) {
        undef $_syntax;
    }

    ## create a reusable object
    $_syntax = _new_engine( $engine_name );

    if ($_syntax) {
        $_syntax->logging( sprintf 'using the engine %s', $engine_name );
    }
    else {
        error 'could not create a IkiWiki::Plugin::syntax object';
    }
    
    return $_syntax;
}

sub _new_engine {
    my  $name       =   shift;
    my  $engine     =   sprintf 'IkiWiki::Plugin::syntax::%s', $name;
    my  $object     =   undef;

    eval "use ${engine}";

    if (not @_) {
        if (not $object = $engine->new( )) {
            $object = IkiWiki::Plugin::syntax::Simple->new();
        }
    }

    return $object;
}

sub preprocess (@) { #{{{
    my %params = (
        language        =>  undef,      ### plugin parameters
        description     =>  undef,      #
        text            =>  undef,      #
        file            =>  undef,      #
        linenumbers     =>  0,          #
        formatcomments  =>  0,          ###
        force_subpage   =>  0,          ###  Ikiwiki parameters
        page            =>  undef,      #
        destpage        =>  undef,      ###
        @_
    );

    #   engine change ? 
    if (defined( $params{engine} )) {
        _change_engine( $params{engine} );
    }

    #   check parameters
    eval {
        _clean_up_parameters( \%params );
    };

    if ($@) {
        if (my $ex = Syntax::X::Parameters::None->caught()) {
            # show the plugin info
            return _info_response();
        } else {
            return $_syntax->fail_response( $ex );
        }
    }

    $_syntax->logging( sprintf 'set language to %s', $params{language} );

    ### getting syntax highlight in html format ...  
    eval {
        $_syntax->syntax_highlight( %params );
        };

    if (my $ex = $@) {
        return $_syntax->fail_response( $ex );
    }        

    ### decode to utf-8 ...
    # utf8::decode( $syntax_html );

    ###     build the final text with a template named "syntax" or joining html
    #       blocks
    return _build_output( \%params, $_syntax->output() );
} # }}}

sub _build_output {
    my  $params_ref =   shift;
    my  $html_text  =   shift;
    my  %params     =   (
            language    =>  $_syntax->language(),
            title       =>  $params_ref->{title},
            description =>  $params_ref->{description},
            text        =>  $html_text,
            url         =>  defined $params_ref->{file} 
                            ? IkiWiki::urlto( $params_ref->{file}, 
                                              $params_ref->{page} )
                            : undef,
        );

    if ($use_template) {
        # take a template reference             
        my $tmpl = template('syntax.tmpl', default_escape => 0);
        
        # set substitutions variables            
        $tmpl->param( %params );

        # and process ..
        return $tmpl->output(); 
    }
    else {
        return _manual_output( %params );
    }
}

sub _manual_output {
    my  %params     =   @_;
    my  @html       =   ();

    if (defined $params{title}) {
        push(@html, $_syntax->css('title', $params{title}));
    }

    if (defined $params{url}) {
        push(@html, $params{url});
    }

    if (defined $params{text}) {
        push(@html, $_syntax->css('syntax', $params{text} ) );
    }

    if (defined $params{description}) {
        push(@html, $_syntax->css('description', $params{description}) );
    }

    return join("\n", @html);
}

sub _clean_up_parameters {
    my  $params_ref     =   shift;

    # check for the object availability	        
    if (not $_syntax) {
        Syntax::X->throw( 'syntax plugin not available' );
    }
    else {
        $_syntax->reset_engine();
    }

    ## save a selected group of parameters in the engine object
    $_syntax->page( $params_ref->{page} );
    if ($params_ref->{linenumbers}) {
        $_syntax->linenumbers( 1 );
        $_syntax->first_line_number( $params_ref->{linenumbers} );
    }
    if ($params_ref->{bars}) {
        $_syntax->bars( $params_ref->{bars} );
    }

    #   if defined a external source file ...
    if (defined($params_ref->{file})) {
        ### load file content: $params_ref->{file}
        $_syntax->source( readfile(srcfile($params_ref->{file})) );

        ### add depend from file ...
        add_depends($params_ref->{page}, $params_ref->{file});
    }
    elsif (defined($params_ref->{text})) {
        $_syntax->source( $params_ref->{text} );
    }
    else {
        Syntax::X::Parameters::None->throw( gettext(q(missing text or file parameters)) );
    }

    ## check the source language
    if (not $_syntax->detect_language( 
                    proposed => $params_ref->{language},
                    filename => $params_ref->{file},
                    content  => $_syntax->source() )) {
        Syntax::X::Parameters::Wrong->throw( 
            gettext( q(could not determine or manage the source language) ));
    }
    else {
        # save the language
        $params_ref->{language} = $_syntax->language();
    }

    return;
}

sub _info_response {
    my  %info       =   $_syntax->plugin_info();
    my $tmpl        =   template('syntax_info.tmpl');

    $tmpl->param( %info );

    return $tmpl->output();
}

1; 

__END__

=head1 NAME

IkiWiki::Plugin::syntax - Add syntax highlighting to ikiwiki

=head1 SYNOPSIS

In any source page include the following:

    This is the example code 

    [[syntax language=perl text="""
    #!/usr/bin/perl
    
    print "Hello, world\n";
    """]]

    and this is my bash profile (using file type autodetection )

    [[syntax file="software/examples/mybash_profile" 
        description="My profile" ]]

In order to facilitate the life to the administrator the plugin could create a
html table with information about the engine capabilities. 

Use the directive C<syntax> without any parameters as is:

    This is the syntax engine chart in this site:

    [[syntax ]]

=head1 DESCRIPTION

This plugin adds syntax highlight capabilities to Ikiwiki using third party
modules if they are installed. 

Those modules can be:

=over

=item * L<Syntax::Highlight::Engine::Kate>

Uses the Syntax::Highlight::Engine::Kate package, a port to Perl of the
syntax highlight engine of the Kate text editor.

Copyright (c) 2006 by Hans Jeuken, all rights reserved.

=item * L<Text::VimColor>

This plugin uses the Text::VimColor module and the vim editor.

Copyright 2002-2006, Geoff Richards.

=item * L<IkiWiki::Plugin::syntax::Simple>

This is the default engine. It's a passtrough engine with line numering capability.

=back

and they can be selected at runtime with the C<syntax_engine> parameter. In
case of fail loading the module the plugin switch to use the simple engine.

The module register a preprocessor directive named B<syntax>.

=head2 Parameters

The syntax directive has the following parameters:

=over

=item language (optional)

Name of the source language for select the correct plugin. If not defined the
module will try to determine the appropiated value.

=item description (optional)

Text description for the html link 

=item text

Source text for syntax highlighting. Mandatory if not exists the file
parameter.

=item file

Ikiwiki page name as source text for syntax highlighting. The final html
includes a link to it for direct download.

=item linenumbers

Enable the line numbers in the final html.

=item bars

Enable the bars feature. The final html text will be label with css tags on the
odd lines.

=item force_subpage

Parameter for inline funcion to the source page

=back

=head2 CSS

The package uses the following list of css tags:

=over

=item

=back

=head1 METHODS/SUBROUTINES

=head2 checkconfig( )

This method is called by IkiWiki main program and the plugin uses it for load
global configuration values and initialize his internals.

=head2 preprocess( )

This method is called when the ikiwiki parser found a C<syntax> directive.
Without parameters the method show information about the external syntax
parser.

=head1 CONFIGURATION AND ENVIRONMENT

IkiWiki::Plugin::syntax uses the following global parameters:

=over

=item syntax_engine (optional)

Set to a keyword for select the engine to use.

=over

=item Kate

Uses the L<Syntax::Highlight::Engine::Kate> as backend.

=item Vim

Uses the L<Text::VimColor> as backend.

=item Simple

Uses the L<IkiWiki::Plugin::syntax::Simple> as backend.

=back

If this parameter is omitted or the external module fails, the plugin switch to
use the Simple engine.

=item syntax_Kate (optional)

Parameters to configure the engine (not implemented yet).

=item syntax_Vim (optional)

Parameters to configure the engine (not implemented yet).

=item syntax_Simple (optional)

Parameters to configure the engine (not implemented yet).

=back

=head1 DEPENDENCIES

The module needs the following perl packages:

=over

=item L<Module::Build::IkiWiki>

Extension to L<Module::Build> for build and install ikiwiki plugins.

=item L<Class::Accessor::Fast>

=item L<Test::More>

=item L<Exception::Class>

=item L<HTML::Entities>

=item L<HTML::Template>

=item L<URI::Escape>

=back

And it recommends:

=over

=item L<Syntax::Highlight::Engine::Kate>

=item L<Text::VimColor>

=back

=head1 BUGS AND LIMITATIONS

Please, see the included file BUGS for a complete list, and report any bugs or
feature requests to the author.

=head1 FEATURE REQUESTS 

=over 

=item Operate on filenames as wikilinks because the current system works as
pagespecs, and the plugin only operates on a unique page.

Suggested by Steven Black.

=back

=head1 AUTHOR

"Víctor Moral"  C<< victor@taquiones.net >>

=head1 CONTRIBUTORS

=over

=item "Steven Black" C<< yam655@gmail.com >> 

=item "Manoj Srivastava"

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, "Víctor Moral".

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.



