#!perl -w

use strict;
no strict "vars";

use Interval;

print "1..169\n";
$n = 1;

# 1. Y before X
#####################
$Y = new Interval ("01/10/97", "12/10/97");
$X = new Interval ("14/10/97", "20/10/97");
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
$Y = new Interval ("01/10/97", "12/10/97");
$X = new Interval ("12/10/97", "20/10/97");
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
$Y = new Interval ("01/10/97", "12/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("01/10/97", "20/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("01/10/97", "21/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("08/10/97", "12/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("08/10/97", "20/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("08/10/97", "28/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("10/10/97", "12/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("10/10/97", "20/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("10/10/97", "25/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("20/10/97", "25/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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
$Y = new Interval ("22/10/97", "25/10/97");
$X = new Interval ("08/10/97", "20/10/97");
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

