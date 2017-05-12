#line 1 "inc/Module/Install/Inline.pm - /usr/local/share/perl/5.8.3/Module/Install/Inline.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Inline.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1781 $ $DateTime: 2003/10/22 17:14:03 $ vim: expandtab shiftwidth=4

package Module::Install::Inline;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use strict;

sub Inline { $_[0] }

sub write {
    my $self = shift;
    my $name = $self->module_name || $self->name
        or die "Please set name() before calling &Inline->write\n";
    $name =~ s/-/::/g;
    my $object = (split(/::/, $name))[-1] or return;
    my $version = $self->version
        or die "Please set version() or version_from() before calling &Inline->write\n";

    $version =~ /^\d\.\d\d$/ or die << "END";
Invalid version '$version' for $name.
Must be of the form '#.##'. (For instance '1.23')
END

    $self->clean_files('_Inline', "$object.inl");
    $self->build_requires('Inline' => 0.44); # XXX: check for existing? yagni?

    my $class = ref($self);
    my $prefix = $self->_top->{prefix};
    $self->postamble(<<"MAKEFILE");
# --- $class section:

.SUFFIXES: .pm .inl

.pm.inl:
\t\$(PERL) -I$prefix -Mblib -MInline=NOISY,_INSTALL_ -M$name -e1 $version \$(INST_ARCHLIB)

pure_all :: $object.inl

MAKEFILE

    $self->Makefile->write;
}

1;
