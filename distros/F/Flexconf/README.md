# NAME

Flexconf - Configuration files management library and program

# SYNOPSIS

    use Flexconf;

    my $conf = Flexconf->new({k=>'v',...} || nothing)

    # parse or stringify, format: 'json'||'yaml'
    $conf->parse(format => '{"k":"v"}')
    $string = $conf->stringify('format')

    # save or load, format (may be ommitted): 'auto'||'json'||'yaml'
    $conf->load(format => $filename)
    $conf->save(firmat => $filename)
    $conf->load($filename) # autodetect format by file ext
    $conf->save($filename) # autodetect format by file ext

    # replace whole tree
    $conf->data({k=>'v',...})

    # access to root of conf tree
    $root = $conf->data
    $root = $conf->get

    # access to subtree in depth by path
    $module_conf = $conf->get('app.module')

    # assign subtree in depth by path
    $conf->assign('h', {a=>[]})
    $conf->assign('h.a.0', [1,2,3])
    $conf->assign('h.a.0.2', {k=>'v'})

    # copy subtree to another location
    $conf->copy('to', 'from')
    $conf->copy('k.a', 'h.a.0')

    # remove subtree by path
    $conf->remove('k.v')

# DESCRIPTION

Flexconf is base for configuration management

# LICENSE

Copyright (C) Serguei Okladnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Serguei Okladnikov <oklaspec@gmail.com>
