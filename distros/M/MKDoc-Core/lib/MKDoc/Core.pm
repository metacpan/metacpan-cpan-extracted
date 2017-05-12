=head1 NAME

MKDoc::Core - Framework for MKDoc products.


=head1 SUMMARY 

MKDoc is a web content management system written in Perl which focuses on
standards compliance, accessiblity and usability issues, and multi-lingual
websites.

At MKDoc Ltd we have decided to gradually break up our existing commercial
software into a collection of completely independent, well-documented,
well-tested open-source CPAN modules.

Ultimately we want MKDoc code to be a coherent collection of module
distributions, yet each distribution should be usable and useful in itself.

L<MKDoc::Core> is a mod_perl application framework. It doesn't do anything
useful on its own, however it is used by products such as L<MKDoc::Auth> and
L<MKDoc::Forum> which provide functionality.

L<MKDoc::Core> is designed to let you setup multiple websites using apache
virtual hosting. It also provides L<MKDoc::Setup>, a base setup class which
lets you easily install products onto each site.

For some more blurb about what L<MKDoc::Core> is and does, you can consult
L<MKDoc::Core::Article::Overview>.


=head1 INSTALLATION

=head2 Install the L<MKDoc::Core> distribution. 

Install the module on your system. If you are using CPAN, this is done easily:

  perl -MCPAN -e 'install MKDoc::Forum'

CPAN should pull out any dependencies.

=head2 Set up the L<MKDoc::Core> master directory.

The master directory is used to place resources which are common to all the
L<MKDoc::Core> sites which you will want to install on your system such as
templates, graphics, and some apache configuration.

You need to set up the master directory I<only once>. Once this is done, you
will be able to add new L<MKDoc::Core> sites without having to re-do this step.
More importantly, once the master directory is set up you will not need to
touch your apache config files (or any config file for the matter) in order to
install new sites.

Please read L<MKDoc::Setup::Core> to learn how to deploy the master directory.

=head2 Set up at least an L<MKDoc::Core> site.

Once you have set up the master directory, you need to install at least one
L<MKDoc::Core> site. This is done using L<MKDoc::Setup::Site>. Please refer to
L<MKDoc::Setup::Site> for more details on how to do this.

=head2 Set up one or more products on your L<MKDoc::Core> site(s).

Once you have a working, basic L<MKDoc::Core> site, you can add compliant
products in order to add functionality to the site. You could try out
L<MKDoc::Auth> or L<MKDoc::Forum>.


=head1 CUSTOMIZATION

If you don't like the default templates, you can change the look and feel of by
customizing them as appropriate.

In order to do so, you need to copy the default templates in your site
directory as follows:

  mkdir -p /var/www/example.com/resources
  tar zxvf MKDoc-Core-xx.tgz
  cp -a MKDoc-Core-xx/lib/MKDoc/resources/* /var/www/example.com/resources

The templates which now live in /var/www/example.com/resources will be used for
the site example.com instead of the default ones.

You might also want to customize the templates for all L<MKDoc::Core> sites
rather than one specific site. In this case, simply replace your site directory
by your L<MKDoc::Core> master directory.

=cut
package MKDoc::Core;
use MKDoc::Core::Init;
use MKDoc::Core::Language;
use strict;
use warnings;


our $VERSION = '0.91';


sub process
{
    my $class = shift;
    MKDoc::Core::Init::init();
    $class->main();
    MKDoc::Core::Init::clean();
}



sub main
{
    my $class  = shift;
    my @plugin = $class->plugin_list();

    local $::MKD_Current_Plugin;
    for my $pkg (@plugin) { main_import ($pkg) }

    for my $pkg (@plugin)
    {
        $::MKD_Current_Plugin = $pkg;
        my $ret = $pkg->main;
        last if (defined $ret and $ret eq 'TERMINATE');
    }
}



sub plugin_list
{
    my $class = shift;
    $::MKD_Plugin_List ||= do {

        # this is for backwards compatibility with MKDoc 1.6
        if (defined $ENV{MKD__PLUGIN_LIST})
        {
            eval "use MKDoc::Config";
            my @plugin = MKDoc::Config->config_lines ( MKDoc::Config->PLUGIN_LIST );
            \@plugin;
        }
        else
        {
            opendir DD, $ENV{SITE_DIR} . '/plugin';
            my @files = sort grep /^\d\d\d\d\d_/, readdir (DD);
            closedir DD;
            [ map { s/^\d\d\d\d\d_//; $_ } @files ];
        }
    };

    return @{$::MKD_Plugin_List};
}



sub main_import
{
    my $pkg  = shift;

    my $file = $pkg;
    $file    =~ s/::/\//g;
    $file   .= '.pm';

    $INC{$file} && return;

    require $file;    
    import $pkg;
}


sub core_dir
{
    return $ENV{MKDOC_DIR};
}


sub site_dir
{
    return $ENV{SITE_DIR};
}


1;


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal> TAL for perl
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut


__END__
