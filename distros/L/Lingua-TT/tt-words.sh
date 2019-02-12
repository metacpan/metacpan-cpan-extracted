#!/bin/bash

exec sed '/^$/d; /^%%/d;' "$@"
