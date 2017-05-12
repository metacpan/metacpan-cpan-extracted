#!perl -w
# <Allen overlaps> relative intervals
#######################################
use strict;
no strict "vars";
use Interval;
use Date::Manip;
&Date_Init("DateFormat=non-US");

print "1..169\n";
$n = 1;

# 1. Y before X
#####################
$Y = new Date::Interval ('NOBIND 2 days', 'NOBIND 3 days');
$X = new Date::Interval ('NOBIND 12 days', 'NOBIND 13 days');
if ($Y->AllenBefore ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 2. Y meets X
#####################
$Y = new Date::Interval ('NOBIND 2 days', 'NOBIND 3 days');
$X = new Date::Interval ('NOBIND 3 days', 'NOBIND 34 days');
if (!$Y->AllenBefore ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenMeets ($X))          {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 3. Y left overlaps X
############################
$Y = new Date::Interval ('NOBIND 2 days', 'NOBIND 13 days');
$X = new Date::Interval ('NOBIND 10 days', 'NOBIND 23 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenLeftOverlaps ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 4. Y left covers X
##########################
$Y = new Date::Interval ('NOBIND 2 days', 'NOBIND 13 days');
$X = new Date::Interval ('NOBIND 8 days', 'NOBIND 13 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenLeftCovers ($X))     {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 5. Y covers X
#########################
$Y = new Date::Interval ('NOBIND 2 days', 'NOBIND 13 days');
$X = new Date::Interval ('NOBIND 4 days', 'NOBIND 6 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenCovers ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 6. Y starts X
#########################
$Y = new Date::Interval ('NOBIND 2 days', 'NOBIND 13 days');
$X = new Date::Interval ('NOBIND 2 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 7. Y equals X
#########################
$Y = new Date::Interval ('NOBIND 8 days', 'NOBIND 20 days');
$X = new Date::Interval ('NOBIND 8 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenEquals ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 8. Y right covers X
#########################
$Y = new Date::Interval ('NOBIND 8 days', 'NOBIND 28 days');
$X = new Date::Interval ('NOBIND 8 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenRightCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 9. Y during X
#########################
$Y = new Date::Interval ('NOBIND 10 days', 'NOBIND 12 days');
$X = new Date::Interval ('NOBIND 8 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 10. Y finishes X
#########################
$Y = new Date::Interval ('NOBIND 10 days', 'NOBIND 20 days');
$X = new Date::Interval ('NOBIND 08 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 11. Y right overlaps X
#########################
$Y = new Date::Interval ('NOBIND 10 days', 'NOBIND 25 days');
$X = new Date::Interval ('NOBIND 08 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenRightOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 12. Y extends X
#########################
$Y = new Date::Interval ('NOBIND 20 days', 'NOBIND 25 days');
$X = new Date::Interval ('NOBIND 8 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenExtends ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenAfter ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;

# 13. Y after X
#########################
$Y = new Date::Interval ('NOBIND 22 days', 'NOBIND 25 days');
$X = new Date::Interval ('NOBIND 8 days', 'NOBIND 20 days');
if (!$Y->AllenBefore ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenMeets ($X))         {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftOverlaps ($X))  {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenLeftCovers ($X))    {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenCovers ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenStarts ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenEquals ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightCovers ($X))   {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenDuring ($X))        {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenFinishes ($X))      {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenRightOverlaps ($X)) {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if (!$Y->AllenExtends ($X))       {print "ok $n\n";} else {print "not ok $n\n";} $n++;
if ($Y->AllenAfter ($X))          {print "ok $n\n";} else {print "not ok $n\n";} $n++;

