#!/bin/bash
# "source" this script in your .bashrc to configure nuggit (if not already installed for all users)

# Get directory of this script (https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

export PATH=${DIR}/bin:${PATH}
export PERL5LIB=${DIR}/lib:${PERL5LIB}

# Autocomplete (ngt will provide autocomplete responses for itself, when appropriate env variable is set)
complete -C ngt ngt

# cd to specified folder relative to nuggit base.
# Note: Accepts up to two arguments for convenience when building aliases.
ngtcd() {
    cd $(ngt base)/$1/$2
}
