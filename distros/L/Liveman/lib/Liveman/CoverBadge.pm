package Liveman::CoverBadge;

use common::sense;
use File::Basename qw/dirname/;
use File::Slurper qw/read_text write_text/;
use File::Path qw/mkpath/;

# Конструктор
sub new {
	my $cls = shift;
	
	bless {
        coverage_html => 'cover_db/coverage.html',
        badge_path => 'doc/badges/total.svg',
		template => << 'END',
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="112" height="20"><linearGradient id="smooth" x2="0" y2="100%"><stop stop-opacity=".1" offset="0" stop-color="#bbb"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="round"><rect width="112" rx="3" height="20" fill="#fff"/></clipPath><g clip-path="url(#round)"><rect width="65" fill="$FILL" height="20"/><rect width="47" x="65" fill="$COLOR" height="20"/><rect width="112" fill="url(#smooth)" height="20"/></g><g font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11" fill="#fff" text-anchor="middle"><text y="15" fill="#010101" x="33.5" fill-opacity=".3">$LEFT</text><text y="14" x="33.5">$LEFT</text><text x="87.5" fill-opacity=".3" fill="#010101" y="15">$RIGHT</text><text y="14" x="87.5">$RIGHT</text></g></svg>
END
        @_
	}, ref $cls || $cls;
}

# Создаёт svg
sub svg {
	my ($self, $percentage) = @_;

    my $color = $percentage >= 90 ? '#00FA9A' :
                $percentage >= 80 ? '#ADFF2F' :
                $percentage >= 70 ? '#FFFF00' : '#DC143C';

	my $svg = $self->{template};
	$svg =~ s/\$LEFT/coverage/g;
	$svg =~ s/\$RIGHT/$percentage%/g;
	$svg =~ s/\$COLOR/$color/g;
	$svg =~ s/\$FILL/#24292E/g;
	$svg
}

# Загружает покрытие из отчёта html
sub load {
	my ($self) = @_;
	
    my $report = read_text $self->{coverage_html};

    ($self->{coverage}) =  $report =~ m!(\d+(?:\.\d+)?)\s*</td>\s*</tr>\s*</tfoot>!s;

    $self
}

# Сохраняет бэйдж
sub save {
	my ($self) = @_;

	mkpath dirname $self->{badge_path};
	
    write_text $self->{badge_path}, $self->svg($self->{coverage});

    $self
}

1;