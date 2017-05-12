package Module::Install::Admin::WriteAll;

use Module::Install::Base;
@ISA = qw(Module::Install::Base);

$VERSION = '0.67';

sub WriteAll {
    my ($self, %args) = @_;

    if (-e 'Makefile.PL') {
        $self->load('Makefile');
        if ($args{check_nmake}) {
            $self->load($_) for qw(Makefile check_nmake can_run get_file);
        }
    }

    if (-e 'Build.PL') {
        $self->load('Build');
        if ($self->sign and !-e 'MANIFEST.SKIP') {
            local *FH;
            open FH, '>MANIFEST.SKIP' or die $!;
            print FH <<'END_MANIFEST_SKIP';
#defaults
^Makefile$
^blib/
^pm_to_blib$
^blibdirs$
^Build$
^_build/
END_MANIFEST_SKIP
            close FH;
            open FH, '>>MANIFEST' or die $!;
            print FH "MANIFEST.SKIP";
            close FH;
        }
    }
}

1;
