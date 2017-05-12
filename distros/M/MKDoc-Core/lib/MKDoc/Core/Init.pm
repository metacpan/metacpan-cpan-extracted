=head1 NAME

MKDoc::Core::Init - MKDoc Initialization Framework


=head1 SUMMARY

The MKDoc Initialization is done much like the way the plugins are processed,
except that the initialization modules cannot interrupt the initialization chain
unless they choose to die(), which triggers a 500 Internal Server Error.

Initialization modules which are registered in $ENV{SITE_DIR}/init are executed
on each request within MKDoc::Init.

Under mod_perl, L<MKDoc::Core::Init> runs as a PerlInitHandler.

Under mod_cgi, L<MKDoc::Core::Init> runs before any plugin is invoked.

See L<MKDoc::Core::Init::Petal> for an example of initialization module.

=cut
package MKDoc::Core::Init;
use warnings;
use strict;


sub handler
{
    clean();
    init();
    return 1;
}


=head2 $class->init();

Sets all the variables, database connections, etc. before the query is
executed.

=cut
sub init
{
    $::MKD_INIT && return;

    for my $pkg (_init_list())
    {
        main_import ($pkg);
        $pkg->init();
    }
    $::MKD_INIT = 1;
}


sub _init_list
{
    my $class = shift;
    $::MKD_Init_List ||= do {
        opendir DD, conf_site_dir() . '/init';
        my @files = sort grep /^\d\d\d\d\d_/, readdir (DD);
        closedir DD;

        [ map { s/^\d\d\d\d\d_//; $_ } @files ];
    };

    return @{$::MKD_Init_List};
}



=head2 $class->clean();

Resets all the variables which look like $::MKD_<something> to undef.

=cut
sub clean
{
    foreach my $key (keys %::)
    {
        $key =~ /^MKD_/ and do { $ {$::{$key}} = undef }
    }
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


sub conf_site_dir
{
    return $ENV{SITE_DIR};
#    $ENV{MOD_PERL} ?
#        Apache->server()->dir_config ('SITE_DIR') :
#        $ENV{SITE_DIR};
}


1;


__END__


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
