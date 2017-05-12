package Magical::Hooker::Decorate::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [],
          'deps' => [],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/Magical/Hooker/Decorate/Install/Files.pm") {
			$CORE = $_ . "/Magical/Hooker/Decorate/Install/";
			last;
		}
	}

1;
