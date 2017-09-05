use Test::More;
use Test::Deep;

use File::ArchivableFormats;
use MIME::Types;

my $af      = File::ArchivableFormats->new();
my $mt      = MIME::Types->new();
my $qr_ext  = qr/^\.\S+$/;

foreach my $driver ($af->installed_drivers) {
    test_driver($driver);
}

sub get_mt {
    my $type = shift;
    $type =~ s/^\.//g;
    $type =~ s/\s*//g;
    return $mt->mimeTypeOf($type);
}

sub test_driver {
    my $driver   = shift;
    my $prefered = $driver->prefered_formats;

    foreach (sort keys %$prefered) {
        if ($_ =~ /^\./) {
            my $ext = $_;
            like($ext, $qr_ext, "Valid extension: '$ext'");
            my $mimetype = get_mt($ext);
            if ($mimetype) {
                fail(
                    sprintf(
                        "'%s' has mimetype '%s' but it is not defined plugin %s",
                        $ext, $mimetype, $driver->name
                    )
                );
            }
            else {
                TODO : {
                    local $TODO = "Unknown MIME type for $ext";
                    fail(
                        sprintf(
                            '"%s" has no mimetype in %s',
                            $ext, $driver->name
                        )
                    );
                }
            }
        }
        else {
            my $type = $_;
            my $exts = $driver->get_info($type)->{allowed_extensions};
            EXT: foreach my $ext (@$exts) {
                like($ext, $qr_ext, "Valid extension for mimetype $type: '$ext'");
                my $mimetype = get_mt($ext);
                next EXT if !$mimetype;
                if ($mimetype eq $type) {
                    pass(sprintf(
                        "'%s' has mimetype '%s' in plugin %s",
                        $ext, $mimetype, $driver->name
                    ));
                    next EXT;
                }

                if ($driver->is_archivable($type)) {
                    my $other_exts = $driver->get_info($type)->{allowed_extensions};
                    cmp_deeply($exts, $other_exts, sprintf(
                        "'%s' has mimetype '%s' in plugin %s",
                        $ext, $mimetype, $driver->name
                    ));
                }
                else {
                    fail(
                        sprintf(
                            "'%s' has mimetype '%s' but it is not defined plugin %s",
                            $ext, $mimetype, $driver->name
                        )
                    );
                }
            }
        }
    }
}

done_testing;
