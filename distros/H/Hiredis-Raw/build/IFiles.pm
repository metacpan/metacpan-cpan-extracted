package Hiredis::Raw::Install::Files;

$self = {
          'deps' => [
                      'XS::Object::Magic'
                    ],
          'inc' => '-I/usr/include/hiredis',
          'libs' => '-L/usr/lib -lhiredis',
          'typemaps' => [
                          'typemap'
                        ]
        };

@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/Hiredis/Raw/Install/Files.pm") {
			$CORE = $_ . "/Hiredis/Raw/Install/";
			last;
		}
	}

	sub deps { @{ $self->{deps} }; }

	sub Inline {
		my ($class, $lang) = @_;
		if ($lang ne 'C') {
			warn "Warning: Inline hints not available for $lang language
";
			return;
		}
		+{ map { (uc($_) => $self->{$_}) } qw(inc libs typemaps) };
	}

1;
