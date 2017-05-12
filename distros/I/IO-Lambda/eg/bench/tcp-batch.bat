@echo off
echo "Lambda using select"
perl tcp-lambda.pl
echo "Lambda using select, optimized"
perl tcp-lambda-optimized.pl
echo "Lambda using AnyEvent"
perl tcp-lambda.pl --anyevent
echo "Lambda using AnyEvent, optimized"
perl tcp-lambda-optimized.pl --anyevent
echo "Raw sockets using select"
perl tcp-raw.pl
echo "POE using select, components"
perl tcp-poe-components.pl
echo "POE using select, raw sockets"
perl tcp-poe-raw.pl
echo "POE using select, optimized"
perl tcp-poe-optimized.pl
