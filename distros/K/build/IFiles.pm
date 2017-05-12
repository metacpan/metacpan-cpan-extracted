package K::Install::Files;

$self = {
          'inc' => '-Iq',
          'typemaps' => [
                          'typemap'
                        ],
          'deps' => [],
          'libs' => '-lpthread'
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/K/Install/Files.pm") {
			$CORE = $_ . "/K/Install/";
			last;
		}
	}

1;
