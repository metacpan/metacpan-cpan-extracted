package DotsForArrows;
use Filter::Simple;
FILTER { s/\b\.(?=[a-z_\$({[])/->/gi };
