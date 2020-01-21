requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::NeedsDisplay';
};

on 'configure' => sub {
    requires 'Alien::FLTK', '1.3.5';
    requires 'Template::Liquid';
    requires 'Test::NeedsDisplay'; # BINGO's smoker ignores required mods in 'test' metadata
};
