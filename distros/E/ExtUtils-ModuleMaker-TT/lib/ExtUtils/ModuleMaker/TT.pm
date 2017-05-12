use strict;
use warnings;

package ExtUtils::ModuleMaker::TT;
# ABSTRACT: Makes skeleton modules with Template Toolkit templates (UNMAINTAINED)
our $VERSION = '0.94'; # VERSION

use Path::Class 0.15;
use Template 2.14;

# predeclare
our %templates;

sub _get_dir_and_file {
    my $module = shift;
    my @layers      = split( /::/, $module->{NAME} );
    my $file        = pop(@layers) . '.pm';
    my $dir         = join( '/', 'lib', @layers );
    return ($dir, $file);
}

sub build_single_pm {
    my ($self, $module) = @_;
    my $module_object;
    
    if ( ref($module) ) {
        if ( $module == $self) {
            $module_object = $module;
        } else {
            $module_object = { %{$self}, %{$module} };
        }
    } else {
        $module_object = { %{$self}, NAME => $module };
    }
    
    # To support calling this function on a standalone basis, look upwards
    # for a base directory
    # (abs->rel) is a workaround to drop the volume on MSWin32
    my $orig_wd = my $cwd = dir()->absolute;
    my $root_dir = dir(q{})->absolute;
    unless ($self->{Base_Dir}) {
        while (! $cwd->subsumes($root_dir)) {
            chdir $cwd;
            if ( -e 'MANIFEST' and -d 'lib' ) {
                $self->{Base_Dir} = $cwd; 
                last;
            }
            $cwd = $cwd->parent;
        }
        chdir $orig_wd;
        $self->death_message(["Can't locate base directory"]) 
            unless $self->{Base_Dir};
    }    

    my ( $dir, $file ) = _get_dir_and_file( $module_object );
    $self->create_directory( dir($self->{Base_Dir}, $dir ));

    $module_object->{new_method} = $self->build_single_method('new');
    # hack to remove subroutine bit    -- a real new sub is in module.pm template
     $module_object->{new_method} =~ s/sub new {.*}\n//s; 
    # hack to add class name to call new in example
     $module_object->{new_method} =~ s/\$rv = /\$rv = $module_object->{NAME}->/s; 
     
    $self->print_file( 
        file( $dir, $file ), 
        $self->text_pm_file( $module_object ) 
    );

    (my $clean_name = $module_object->{NAME} ) =~ s/::/_/g;
    my $testfile = file( "t", $clean_name . ".t" );
    $self->print_file(
        $testfile,
        $self->text_test( $clean_name, $module_object )
    );

    chdir $orig_wd;
    return 1;
}

sub build_single_method {
    my ($self,$method_name) = @_;
    my $results;
    
    my $tt = ( $self->{'TEMPLATE_DIR'} ? 
        Template->new({'INCLUDE_PATH' => $self->{'TEMPLATE_DIR'} }) :
        Template->new() )
        or $self->death_message([ "Template error: $Template::ERROR" ]);
    my $template_text = $templates{'method'};
    $tt->process( $self->{'TEMPLATE_DIR'} ? 'method' : \$template_text,
                  { %{ $self }, method_name => $method_name }, \$results )
        or $self->death_message([ "Could not write method '$method_name': " 
            . $tt->error()  ]);
    return $results;    
}


#--------------------------------------------------------------------------#
# subclassing ExtUtils::ModuleMaker::StandardText
#--------------------------------------------------------------------------#


sub text_README {
    my $self = shift;
    return $self->process_template( 'README', $self );
}

sub text_Todo {
    my $self = shift;
    return $self->process_template( 'Todo', $self );
}

sub text_Changes {
    my $self = shift;
    return $self->process_template( 'Changes', $self );
}

sub text_test {
    my ( $self, $test_filename, $module_data ) = @_;
    return $self->process_template( 'test.t', $module_data );
}

sub text_test_multi {
    my ( $self, $testfilename, $pmfilesref ) = @_;
    my @pmfiles = @{$pmfilesref};
    return $self->process_template( 'test.t', $self );
}

sub text_Makefile {
    my $self = shift;
    return $self->process_template( 'Makefile.PL', $self );
}


sub text_Buildfile {
    my $self = shift;
    return $self->process_template( 'Build.PL', $self );
}

sub text_proxy_makefile {
    my $self = shift;
    return $self->process_template( 'Proxy_Makefile.PL', $self );
}

sub text_MANIFEST_SKIP {
    my $self = shift;
    return $self->process_template( 'MANIFEST.SKIP', $self );
}

sub text_pod_coverage_test {
    my $self = shift;
    return $self->process_template( 'pod_coverage.t', $self );
}

sub text_pod_test {
    my $self = shift;
    return $self->process_template( 'pod.t', $self );
}

sub text_pm_file {
    my $self = shift;
    my $module_data = shift;
      
    return $self->process_template( 'module.pm', $module_data );
}

#--------------------------------------------------------------------------#
# Template handling
#--------------------------------------------------------------------------#

sub create_template_directory {
    my ($class, $dir) = @_;
    dir($dir)->mkpath;
    for my $template ( keys %templates ) {
        my $target = dir($dir, $template);
        open (FILE, ">", $target) or croak ("Could not write '$target', $!");
        print FILE ( $templates{$template} );
        close FILE;
    }
    return 1;
}

sub process_template {
    my ($self, $template, $data) = @_;
    my $tt = ( $self->{'TEMPLATE_DIR'} ? 
        Template->new({'INCLUDE_PATH' => $self->{'TEMPLATE_DIR'} }) :
        Template->new() )
        or $self->death_message([ "Template error: $Template::ERROR" ]);
    my $template_text = $templates{$template};
    my $output_text;
    $tt->process( $self->{'TEMPLATE_DIR'} ? $template : \$template_text,
                  $data, \$output_text )
        or $self->death_message([ 
            "Could not generate $template contents: " . $tt->error() 
        ]);
    return $output_text;
}

#-------------------------------------------------------------------------#
    
    $templates{'README'} = <<'EOF';
If this is still here it means the programmer was too lazy to create the readme file.

You can create it now by using the command shown below from this directory:

pod2text [%  NAME %] > README

At the very least you should be able to use this set of instructions
to install the module...

[%- IF BUILD_SYSTEM == 'ExtUtils::MakeMaker' -%]
perl Makefile.PL
make
make test
make install
[%- ELSE -%]
perl Build.PL
perl Build
perl Build test
perl Build install
[%- END -%]

If you are on a windows box you should use 'nmake' rather than 'make'.
EOF

#-------------------------------------------------------------------------#
    
    $templates{'Changes'} = <<'EOF';
Revision history for Perl module [%  NAME %]

[%  VERSION %] [% timestamp %]
    - original skeleton created with ExtUtils::ModuleMaker::TT
EOF
    
    $templates{'Todo'} = <<'EOF';
TODO list for Perl module [%  NAME %]

- Nothing yet

EOF
    
#-------------------------------------------------------------------------#
    
    $templates{'Build.PL'} = <<'EOF';
use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new( 
    module_name         => '[%  NAME %]',
    dist_author         => '[%  AUTHOR %] <[% EMAIL %]>',
[%- IF LICENSE.match('perl|gpl|artistic') %]
    license             => '[%  LICENSE %]',
[%- END %]
    create_readme       => 1,
    create_makefile_pl  => 'traditional',
    requires        => {
        # module requirements here
    },
    build_requires  => { 
        Test::Simple => 0.44,
    },
)->create_build_script;
EOF

#-------------------------------------------------------------------------#
    
    $templates{'Makefile.PL'} = <<'EOF';
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => '[%  NAME %]',
    VERSION_FROM => '[%  FILE %]', # finds $VERSION
    AUTHOR       => '[%  AUTHOR %] ([%  EMAIL %])',
    ABSTRACT     => '[% ABSTRACT %]',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
EOF

#-------------------------------------------------------------------------#
    
    $templates{'Proxy_Makefile.PL'} = <<'EOF';
unless (eval "use Module::Build::Compat 0.02; 1" ) {
  print "This module requires Module::Build to install itself.\n";

  require ExtUtils::MakeMaker;
  my $yn = ExtUtils::MakeMaker::prompt
    ('  Install Module::Build from CPAN?', 'y');

  if ($yn =~ /^y/i) {
    require Cwd;
    require File::Spec;
    require CPAN;

    # Save this 'cause CPAN will chdir all over the place.
    my $cwd = Cwd::cwd();
    my $makefile = File::Spec->rel2abs($0);

    CPAN::Shell->install('Module::Build::Compat');

    chdir $cwd or die "Cannot chdir() back to $cwd: $!";
    exec $^X, $makefile, @ARGV;  # Redo now that we have Module::Build
  } else {
    warn " *** Cannot install without Module::Build.  Exiting ...\n";
    exit 1;
  }
}
Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();

EOF

#-------------------------------------------------------------------------#
    
    $templates{'MANIFEST.SKIP'} = <<'EOF';
# Version control files and dirs.
\bRCS\b
\bCVS\b
,v$
.svn/

# ExtUtils::MakeMaker generated files and dirs.
^MANIFEST\.(?!SKIP)
^Makefile$
^blib/
^blibdirs$
^PM_to_blib$
^MakeMaker-\d
                                                                                                                    
# Module::Build
^Build$
^_build

# Temp, old, vi and emacs files.
~$
\.old$
^#.*#$
^\.#
\.swp$
\.bak$
EOF

#-------------------------------------------------------------------------#
    
    $templates{'test.t'} = <<'EOF';
# [%  NAME %] - check module loading and create testing directory

use Test::More tests => [% IF NEED_NEW_METHOD %] 2 [% ELSE %] 1 [% END %];

BEGIN { use_ok( '[%  NAME %]' ); }
[% IF NEED_NEW_METHOD %]
my $object = [%  NAME %]->new ();
isa_ok ($object, '[%  NAME %]');
[%- END %]
EOF

#-------------------------------------------------------------------------#
    
    $templates{'module.pm'} = <<'EOF';
package [%  NAME %];
use strict;
use warnings;
use Carp;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = "0.92";
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

[%- IF NEED_POD %]
#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

# Below is the stub of documentation for your module. You better edit it!

!=head1 NAME

[%  NAME %] - Put abstract here 

!=head1 SYNOPSIS

 use [%  NAME %];
 blah blah blah

!=head1 DESCRIPTION

Description...

!=head1 USAGE

Usage...

!=cut

[% END %]
[%- IF NEED_NEW_METHOD -%]
[% new_method -%]
sub new {
    my ($class, $parameters) = @_;
    
    croak "new() can't be invoked on an object"
        if ref($class);
        
    my $self = bless ({ }, $class);
    return $self;
}
[% END %]
1; #this line is important and will help the module return a true value
__END__
[% IF NEED_POD %]
[%- IF CHANGES_IN_POD -%]
!=head1 HISTORY
[% END %]
!=head1 BUGS

Please report bugs using the CPAN Request Tracker at L<http://rt.cpan.org/>

!=head1 AUTHOR

[% AUTHOR %] [% IF CPANID %]([% CPANID %])[% END %]
[%- IF ORGANIZATION %]

[% ORGANIZATION %]
[%- END %]

[% EMAIL %]

[% WEBSITE %]

!=head1 COPYRIGHT

Copyright (c) [% COPYRIGHT_YEAR %] by [% AUTHOR %]

[%  LicenseParts.COPYRIGHT %]

!=cut
[%- END -%]
EOF

#-------------------------------------------------------------------------#
    
$templates{'method'} = <<'EOF';
#--------------------------------------------------------------------------#
# [% method_name %]()
#--------------------------------------------------------------------------#

[% IF NEED_POD -%]
!=head2 [% method_name %]

 $rv = [% method_name %]();

Description of [% method_name %]...

!=cut
[%- END %]

sub [% method_name %] {
[% IF NEED_NEW_METHOD -%]
    my ($self) = @_;
[% END -%]

}

EOF

#--------------------------------------------------------------------------#

$templates{'pod_coverage.t'} = <<'END_OF_POD_COVERAGE_TEST';
#!perl -T

use Test::More;

eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage"
    if $@;

eval "use Pod::Coverage 0.17";
plan skip_all => "Pod::Coverage 0.17 required for testing POD coverage"
    if $@;

all_pod_coverage_ok();
END_OF_POD_COVERAGE_TEST

#----------------------------------------------------------------------#
 
$templates{'pod.t'} = <<'END_OF_POD_TEST';
#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
END_OF_POD_TEST

#--------------------------------------------------------------------------#
# cleanup escaped pod in templates
#--------------------------------------------------------------------------#

for (values %templates) {
    s/^!=([a-z])/=$1/gxms;
}

#--------------------------------------------------------------------------#

1; #this line is important and will help the module return a true value

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::ModuleMaker::TT - Makes skeleton modules with Template Toolkit templates (UNMAINTAINED)

=head1 VERSION

version 0.94

=head1 UNMAINTAINED

This distribution is no longer maintained as the author no longer uses or
recommends it.  If you wish to take it over, please contact the author.

=head1 SYNOPSIS

 use ExtUtils::ModuleMaker;
 my $mmtt = ExtUtils::ModuleMaker->new (
     NAME => 'My::New::Module',
     ALT_BUILD => 'ExtUtils::ModuleMaker::TT',
     TEMPLATE_DIR => '~/.perltemplates',
 );
 $mmtt->complete_build();

=head1 DESCRIPTION

I<Note: ExtUtils::ModuleMaker has changed substantially in recent releases
and ExtUtils::ModuleMaker::TT has similarly changed substantially to be
compatible with these changes.  Please report any bugs you may find.>

This module extends L<ExtUtils::ModuleMaker> to use Template Toolkit 2 (TT2) to
build skeleton files for a new module.  Templates may either be default
templates supplied within the module or user-customized templates in a
directory specified with the I<TEMPLATE_DIR> parameter.

Summary of Features/Enhancements:

=over 4

=item *

Supports building full module skeletons with all the functionality of 
C<ExtUtils::ModuleMaker>

=item *

Supports adding a single .pm file (and corresponding .t file) to an existing
module distribution tree

=item *

Supports creating skeleton text for a single method (generally to be called via
a script from within your favorite editor)

=item *

Creates a template directory containing the default templates for subsequent
user customization

=item *

Templates can access any parameter in the ExtUtils::ModuleMaker object (e.g.
$mmtt, above).   This supports transparent, user-extensible template variables
for use in custom templates

=item * 

Included command-line program I<makeperlmod> provides a command line user
interface for module creation.  Supports reading default configuration settings
from a file and will create a default config file if requested.  These config
files extend and/or override an C<ExtUtils::ModuleMaker::Personal::Defaults>
file.  The program can create full distributions, single modules, single
methods, default configuration files or default template directories

=back

Notable changes from ExtUtils::ModuleMaker:

=over 4

=item *

Default templates are generally simpler, as users are expected to customize
their own

=item *

.t files for single .pm files created I<after> the original build are named
after their corresponding .pm file rather than being sequentially numbered.

=item *

In the command-line program, I<COMPACT> style is set by default

=back

=head1 USAGE

ExtUtils::ModuleMaker::TT is designed to be used with the I<ALT_BUILD> 
parameter of ExtUtils::ModuleMaker.  It replaces much of the functionality
of L<ExtUtils::ModuleMaker::StandardText>.

 use ExtUtils::ModuleMaker;
 my $mmtt = ExtUtils::ModuleMaker->new (
     NAME => 'My::New::Module',
     ALT_BUILD => 'ExtUtils::ModuleMaker::TT',
 );

Generally, users should just use the included command-line program,
L<makeperlmod>.  For example, the following command will create a module
distribution using default settings:

    makeperlmod -n Sample::Module

See the L<makeperlmod> manual page for details on creating a custom configuration
file (for setting author details and other ExtUtils::ModuleMaker options) that
will extend or override defaults set in an
ExtUtils::ModuleMaker::Personal::Defaults file.  The L<CUSTOMIZING TEMPLATES>
section below contains other examples.

When specified as the ALT_BUILD, ExtUtils::ModuleMaker::TT provides several
additional methods as described below.  The L<makeperlmod> source provides a
practical example of such usage. 

=head1 PUBLIC METHODS

=head2 build_single_pm

    $mmtt->build_single_pm( $module );

Creates a new .pm file and a corresponding .t file.

The I<$module> parameter may be either a hash reference containing
configuration options (including I<NAME>) or a string containing the
name of a module, in which case the default configuration will be used.
E.g.:

    $module = { NAME => 'Sample::Module', NEED_POD => 0 };

or

    $module = 'Sample::Module';

This method must be able to locate the base directory of the distribution in
order to correctly place the .pm and .t files.  A I<complete_build()> call sets
the I<Base_Dir> parameter appropriately as it creates the distribution
directory.  When called on a standalone basis (without a prior
I<complete_build()> call), the caller must be in a directory within the
distribution tree.  

When I<Base_Dir> is not set, this method will look in the current directory for
both a 'MANIFEST' file and a 'lib' directory.  If neither are found, it will
scan upwards in the directory tree for an appropriate directory.  Requiring
both files prevents mistakenly using either a template directory or a unix root
directory.  The method will croak if a proper directory cannot be found.  The
working directory in use prior to the method being called will be restored when
the method completes or croaks. Returns a true value if successful.

=head2 build_single_method

    $mmtt->build_single_method( $method_name );

Returns a string with a skeleton subroutine for the given I<$method_name>.
Used internally, but made available for use in scripts to be called from
your favorite editor.

=head2 create_template_directory

    $mmtt->create_template_directory( $directory );

Creates the named I<$directory> and populates it with a file for each default
template.  These can be customized and the directory used in conjunction with
the I<TEMPLATE_DIR> configuration options.  See L<CUSTOMIZING TEMPLATES>, below.
Returns a true value if successful.

=head2 process_template

    $mmtt->process_template( $template, \%data, $outputfile );

Calls TT2 to fill in the given template and write it to the output file.
Requires a template name, a hash reference of parameters (typically just the
C<$mmtt> object itself), and an outputfile (relative to the base distribution
directory).  If the I<TEMPLATE_DIR> parameter is set, templates will be taken
from there, otherwise the default templates are used.  Returns a true value if
successful.

=head1 CUSTOMIZING TEMPLATES

=head2 Overview

Use the L<makeperlmod> script to create a directory containing a copy of the
default templates.  Alternatively, use the L<create_template_directory> method
directly.  Edit these templates to suit personal taste or style guidelines. 
Be sure to specify a TEMPLATE_DIR configuration option when making
modules or add it to either the ExtUtils::ModuleMaker::Personal::Defaults
file or to a C<makeperlmod> config file.  

=head2 Changes from earlier versions

ExtUtils::ModuleMaker now stores author information in the main object rather
than in a separate hash datastructure.  This will break old templates.

 # Old
 { 
   AUTHOR => { NAME => "John Doe", EMAIL => "john@doe.org" } 
 }
 
 # New
 {
   AUTHOR => "John Doe",
   EMAIL  => "john@doe.org",
 }

=head2 Customizing with makeperlmod

This can all be done quite easily with L<makeperlmod>.  Begin with:

    makeperlmod -d 

This will create a default configuration file and print its location.  See the
makeperlmod manual for details on creating and using named configuration
files.

Next, create a template directory.  Choose a location that is appropriate
for your operating system.  E.g., for unix:

    makeperlmod -t ~/.makeperlmod.templates

Edit the templates as needed. Templates are written with the Template
Toolkit to allow for easy user customization of the contents and layout. See
the L<Template> module for the full syntax or just examine the default
templates for quick changes.

Edit the default configuration file and add a I<TEMPLATE_DIR> parameter.  Use
whatever directory you chose to hold the templates.  Make any other desired
edits to AUTHOR, etc.  For example:

  TEMPLATE_DIR ~/.makeperlmod.templates
  AUTHOR John Q. Public

Presto!  Customization is done.  Now start making modules with

    makeperlmod -n My::New::Module

=head2 Creating custom template variables (use with caution)

When templates are processed, the entire ExtUtils::ModuleMaker object is passed
to the Template Toolkit.  Thus any class data is available for use in
templates.  Users may add custom configuration options ( to I<new>, to the
ExtUtils::ModuleMaker::Personal::Defaults file, or to a makeperlmod config
file) and use these in custom templates.  Be careful not to overwrite any class
data needed elsewhere in the module.

=head2 Default templates

Templates included are:

    * README
    * Changes
    * Todo
    * Build.PL
    * Makefile.PL
    * Proxy_Makefile.PL
    * MANIFEST.SKIP
    * test.t
    * module.pm
    * method
    * pod.t
    * pod_coverage.t

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/ExtUtils-ModuleMaker-TT/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/ExtUtils-ModuleMaker-TT>

  git clone https://github.com/dagolden/ExtUtils-ModuleMaker-TT.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David Golden.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
