use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── class decorator ───────────────────────────────────────────────

{
    my $src = <<'END';
@Component({
selector: 'app-root',
})
class AppComponent {
title = 'app';
}
END
    my $out = r($src);
    like($out, qr/^\@Component\(\{$/m,         '@Component at depth 0');
    like($out, qr/^    selector: 'app-root',$/m,'option at depth 1');
    like($out, qr/^\}\)$/m,                    'closing }) at depth 0');
    like($out, qr/^class AppComponent \{$/m,   'class at depth 0');
    like($out, qr/^    title = 'app';$/m,      'property at depth 1');
}

# ── method decorator ──────────────────────────────────────────────

{
    my $src = <<'END';
class Service {
@Injectable()
getData(): string {
return 'data';
}
}
END
    my $out = r($src);
    like($out, qr/^class Service \{$/m,        'class at depth 0');
    like($out, qr/^    \@Injectable\(\)$/m,    '@Injectable at depth 1');
    like($out, qr/^    getData\(\): string \{$/m, 'method at depth 1');
    like($out, qr/^        return 'data';$/m,  'body at depth 2');
}

done_testing;
