function _dynamicloader_script_completion()
{
    local cur prev opts
    COMPREPLY=()

    if [[ ${COMP_CWORD} == 1 ]] ; then 
      cur="${COMP_WORDS[COMP_CWORD]}"
      prev="${COMP_WORDS[COMP_CWORD-1]}"

      opts="$($1)"

      if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
      fi
    else
      COMPREPLY=( $(compgen -f ${cur}) )
    fi
}
complete -F _dynamicloader_script_completion dynamicloader.pl
