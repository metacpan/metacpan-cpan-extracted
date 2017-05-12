//
//  Callback.h
//  MediaLandscape
//
//  Created by Chris Dolan on 4/28/06.
//  Copyright 2006 Clotho Advanced Media, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Callback : NSObject {
   id  callbackObj;
   SEL callbackMethod;
   id  callbackData;
}

+(id) create:(id)obj method:(SEL)method;
+(id) create:(id)obj method:(SEL)method data:(id)data;
-(id) init:(id)obj method:(SEL)method;
-(id) init:(id)obj method:(SEL)method data:(id)data;
-(void) invoke:(id)result;

@end
