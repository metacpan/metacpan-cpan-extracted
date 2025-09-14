use v5.40;

package Minima::Project;

use File::Share;
use Path::Tiny;
use Template;

our $tdir = path(
        File::Share::dist_dir('Minima')
    )->child('/templates');
our $verbose = 0;

sub create ($dir, $user_config = {})
{
    my $project = path($dir // '.')->absolute;
    my %config = (
        'static' => 1,
        'verbose' => 0,
        %$user_config
    );
    $verbose = $config{verbose};

    # Test if directory can be used
    if ($project->exists) {
        die "Project destination must be a directory\n"
            unless $project->is_dir;
        die "Project destination must be empty.\n"
            if $project->children;
    } else {
        $project->mkdir;
    }

    chdir $project;

    # Create files
    for my ($file, $content) (get_templates(\%config)) {
        my $dest = path($file);
        my $dir = $dest->parent;

        unless ($dir->is_dir) {
            _info("mkdir $dir");
            $dir->mkdir;
        }

        _info(" spew $dest");
        $dest->spew_utf8($content);
    }
}

sub get_templates ($config)
{
    my %files;
    use Template::Constants qw/ :debug /;
    my $tt = Template->new(
        INCLUDE_PATH => $tdir,
        OUTLINE_TAG => '@@',
        TAG_STYLE => 'star',
    );

    $config->{version} = Minima->VERSION;

    foreach (glob "$tdir/*.[sd]tpl") {
        my $content = path($_)->slurp_utf8;
        $_ = path($_)->basename;
        tr|-|/|;
        tr|+|.|;
        if (/\.dtpl$/) {
            # Process .d(ynamic) template
            my $template = $content;
            my $processed;
            $tt->process(\$template, $config, \$processed);
            $content = $processed;
        }
        s/\.\w+$//;
        $files{$_} = $content;
    }

    map { $_, $files{$_} } sort keys %files;
}

sub _info ($m)
{
    say $m if ($verbose);
}

1;

__END__

=head1 NAME

Minima::Project - Backend for L<minima>, the project manager

=head1 SYNOPSIS

    use Minima::Project;

    Minima::Project::create('app');

=head1 DESCRIPTION

This module is not intended to be used directly by third parties. It is
the backend for L<minima(1)|minima>. No functions are exported by
default.

Templates used for generating projects reside in Minima's F<lib>, which
is stored in a package variable named C<$tdir>. Templates can have two
extensions:

=over 8

=item F<.stpl>

Static templates, which are copied directly.

=item F<.dtpl>

Dynamic templates, which are processed with
L<Template::Toolkit|Template> and then copied.

=back

The C<.[sd]tpl> extensions are removed and the template name is
converted to a proper path by L<C<get_templates>|/get_templates>.

=head1 SUBROUTINES

=head2 create

    sub create ($dir, $config)

Creates a project at C<$dir> with the specified configuration, passed as
a hash reference in C<$config>. The configuration is forwarded to the
templates and is optional.

If the directory is either not empty or not a directory at all, it dies.

This subroutine calls L<C<get_templates>|/get_templates> to retrieve
information about what needs to be generated and where.

=head2 get_templates

    sub get_templates ($config)

Gets the available templates, processes them, and returns a hash
reference containing the paths as keys and contents as values.

Templates are stored in flattened files. This subroutine converts dashes
to directory slashes and plus signs to dots, allowing all template files
to be stored together in a visible structure, even if they represent
hidden files.

=head1 SEE ALSO

L<Minima(3)|Minima>, L<minima(1)|minima>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
