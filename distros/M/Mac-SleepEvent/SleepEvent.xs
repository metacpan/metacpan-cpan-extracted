#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef Move
#undef Move
#endif Move

#import <Foundation/Foundation.h>

@interface SleepEvent: NSObject
@end

@implementation SleepEvent

- (void)asleep {}

- (void)awake {}

- (void)logout {}

@end

MODULE = Mac::SleepEvent		PACKAGE = Mac::SleepEvent		

