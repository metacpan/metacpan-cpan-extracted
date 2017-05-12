Only in Mildew-wip/: blib
diff -r Mildew-0.05/lib/Mildew/Backend/C/So.pm Mildew-wip//lib/Mildew/Backend/C/So.pm
22a23
>         $ENV{LD_RUN_PATH} = SMOP::ld_library_path;
diff -r Mildew-0.05/lib/Mildew/Backend/C/V6.pm Mildew-wip//lib/Mildew/Backend/C/V6.pm
2a3
> use Mildew::Setting::SMOP;
24a26
>         $ENV{LD_RUN_PATH} = join(':',SMOP::ld_library_path(),Mildew::Setting::SMOP::ld_library_path());
113a116,119
>     method path_to_setting {
>         Mildew::Setting::SMOP::ld_library_path() . '/' .
>         'MildewCORE.setting.so';
>     }
diff -r Mildew-0.05/lib/Mildew/Backend/C.pm Mildew-wip//lib/Mildew/Backend/C.pm
65a66,69
>     method path_to_setting {
>         'MildewCORE.setting.so';
>     }
> 
69,75c73,74
<         my $setting_path = 
<             Mildew::Setting::SMOP::ld_library_path() . '/'
<             . string 'MildewCORE.setting.so';
< 
<         $self->load_setting
<         ? call(load => call(new => FETCH(lookup 'MildewSOLoader')),
<             [,FETCH(lookup('$LexicalPrelude'))]) 
---
>         $self->load_setting ? call(load => call(new => FETCH(lookup 'MildewSOLoader')),
>             [string $self->path_to_setting,FETCH(lookup('$LexicalPrelude'))]) 
Only in Mildew-0.05/lib/Mildew/Backend: V6.pm
Only in Mildew-wip/: Makefile
diff -r Mildew-0.05/MANIFEST Mildew-wip//MANIFEST
40d39
< lib/Mildew/Backend/V6.pm
Only in Mildew-wip/: out
Only in Mildew-wip/: pm_to_blib
