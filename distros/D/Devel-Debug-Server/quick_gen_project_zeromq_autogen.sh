#!/bin/sh
export script_type="autogen"
export EX_DEV="~/exDev"
export cwd=${PWD}
export toolkit_path=/home/jeanpat/.toolkit
export lang_type="c cpp c# java shader python vim uc matlab wiki ini make sh batch debug qt swig perl"
export vimfiles_path=".vimfiles.zeromq"
export file_filter="c|C|c\+\+|cc|cp|cpp|cxx|h|H|h\+\+|hh|hp|hpp|hxx|inl|ipp|cs|java|hlsl|vsh|psh|fx|fxh|cg|shd|glsl|py|pyw|pyx|pxd|vim|uc|m|wiki|ini|cfg|mak|mk|Makefile|makefile|sh|SH|bsh|bash|ksh|zsh|bat|log|err|exe|qrc|pro|pri|i|swg|pl|pm|t|yaml"
export file_filter_pattern='\\.c$|\\.C$|\\.c++$|\\.cc$|\\.cp$|\\.cpp$|\\.cxx$|\\.h$|\\.H$|\\.h++$|\\.hh$|\\.hp$|\\.hpp$|\\.hxx$|\\.inl$|\\.ipp$|\\.cs$|\\.java$|\\.hlsl$|\\.vsh$|\\.psh$|\\.fx$|\\.fxh$|\\.cg$|\\.shd$|\\.glsl$|\\.py$|\\.pyw$|\\.pyx$|\\.pxd$|\\.vim$|\\.uc$|\\.m$|\\.wiki$|\\.ini$|\\.cfg$|\\.mak$|\\.mk$|\\.Makefile$|\\.makefile$|\\.sh$|\\.SH$|\\.bsh$|\\.bash$|\\.ksh$|\\.zsh$|\\.bat$|\\.log$|\\.err$|\\.exe$|\\.qrc$|\\.pro$|\\.pri$|\\.i$|\\.swg$|\\.pl$|\\.pm$|\\.t$|\\.yaml$'
export cscope_file_filter="c|C|c\+\+|cc|cp|cpp|cxx|h|H|h\+\+|hh|hp|hpp|hxx|inl|ipp|hlsl|vsh|psh|fx|fxh|cg|shd|glsl"
export cscope_file_filter_pattern='\\.c$|\\.C$|\\.c++$|\\.cc$|\\.cp$|\\.cpp$|\\.cxx$|\\.h$|\\.H$|\\.h++$|\\.hh$|\\.hp$|\\.hpp$|\\.hxx$|\\.inl$|\\.ipp$|\\.hlsl$|\\.vsh$|\\.psh$|\\.fx$|\\.fxh$|\\.cg$|\\.shd$|\\.glsl$'
export dir_filter=""
export support_filenamelist="true"
export support_ctags="true"
export support_symbol="true"
export support_inherit="true"
export support_cscope="true"
export support_idutils="true"
export ctags_cmd="ctags"
export ctags_options=" --c-kinds=+p --c++-kinds=+p --fields=+iaS --extra=+q --languages=c,c++,c#,java,python,vim,matlab,make,sh,perl,c, --langmap=c:+.C,c++:+.H,c++:+.inl,c++:+.ipp,python:+.pyw,c:+.hlsl,c:+.vsh,c:+.psh,c:+.fx,c:+.fxh,c:+.cg,c:+.shd,c:+.glsl,"
if [ -f "./${vimfiles_path}/quick_gen_project_pre_custom.sh" ]; then
    sh ./${vimfiles_path}/quick_gen_project_pre_custom.sh
fi
sh ${toolkit_path}/quickgen/bash/quick_gen_project.sh $1
if [ -f "./${vimfiles_path}/quick_gen_project_post_custom.sh" ]; then
    sh ./${vimfiles_path}/quick_gen_project_post_custom.sh
fi
