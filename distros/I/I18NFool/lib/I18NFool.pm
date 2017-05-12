package I18NFool;
use I18NFool::Extractor;
use I18NFool::ExtractorMerger;
use Getopt::Long;
use Locale::PO;
use warnings;
use strict;

our $VERSION = 0.31;

sub create_potfiles
{
    my $class  = shift;
    my $args   = { @_ };

    my $target = $args->{'target'};
    my @files  = @{$args->{'files'}};

    my @domain_hashes = ();
    foreach my $file (@files)
    {
        print "Extracting $file.\n";
        open FP, "<$file" or do {
            print STDERR "Cannot read-open $file. Reason: $!\n";
            next;
        };

        my $data = join '', <FP>;
        close FP;

        my $domain_hash = eval { I18NFool::Extractor->process ($data) };
        if ($@) { print STDERR "I18NFool::Extractor died parsing $file. Reason:\n\n$@\n\n" }
        else    { push @domain_hashes, $domain_hash }
    }

    print "Merging...\n";
    my $domain_hash = I18NFool::ExtractorMerger->process (@domain_hashes);

    foreach my $domain_key (keys %{$domain_hash})
    {
        my $file = "$target/$domain_key.pot";

        print "Writing $file.\n";
        my $hash = $domain_hash->{$domain_key};

        my $po   = Locale::PO->new();
        Locale::PO->save_file_fromhash ($file, $hash);
    }        
}


1;


=head1 NAME

I18NFool - Internationalization File Object Oriented Leech 


=head1 SYNOPSIS


=head2 Creating a locale directory

This toolkit is mainly targetted at L<Petal>, but it should work with other
templating language which implement the ZPT i18n specification.

First you need a locale directory somewhere for your web app.

  cd /opt/myapp
  mkdir locale
  cd locale


=head2 Extracting i18n: strings.

Then you need to extract a bunch of .pot files from your internationalized
templates. I18NFool assumes that your templates are properly localized.

In the future it will include a tool to find strings which potentially need
localization.

I18NFool creates one .pot file per domain which is defined in the templates.
The format is <domain>.pot.

If no i18n:domain is specified, I18NFool assumes the domain is called
'default'.
 
  find /opt/myapp/templates |egrep '\.html$' |xargs i18nfool-extract 


=head2 Building / syncing the .po files

Create one directory for each language which will need to be translated.

  cd /opt/myapp/locale
  mkdir en_GB
  mkdir en_US
  mkdir fr_FR
  mkdir fr_CA
  mkdir ja

Then run the i18n-update tool.

  cd /opt/myapp/locale
  i18nfool-update

i18n-update will *not* erase your existing .po files, it will update them
nicely using gettext's msgmerge tool.

If the .po file does not exist, it will create a new one.


=head2 Building .mo files

Once you are happy with your set of .po files, it's time to build the .mo files
which are going to be used by your application, for example using
L<Locale::MakeText::Gettext>.

 cd /opt/myapp/locale i18nfool-build


=head1 BUGS. 

This is a totally *alpha* release, so I'd say 'plenty'. Bug reports are
welcome. Patches will do your karma real good.


AUTHORS & LICENSE

  (C) Copyright 2004 MKDoc Ltd. and Laurent Bedubourg

    Authors Jean-Michel Hiver and
    Laurent Bedubourg <lbedubourg@motion-twin.com>.

  This module is free software, it is distributed under the
  same license as Perl itself.

=cut


__END__

